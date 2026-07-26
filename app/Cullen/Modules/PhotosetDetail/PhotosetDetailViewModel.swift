//
//  PhotosetDetailViewModel.swift
//  Cullen
//
//  Presentation Layer - Photoset Detail ViewModel
//

import Foundation
import SwiftUI
import Combine


@MainActor
final class PhotosetDetailViewModel: ObservableObject {
    @Published var state: PhotosetDetailState = .initial
    @Published var aspectRatio: Double = 3.0 / 2.0
    @Published var export: DecisionsExport?
    @Published var scrollTarget: PhotoId? = nil
    @Published private(set) var syncUseCase: PhotosetSyncUseCase?

    var showNextButton: Bool {
        nextPendingId != nil || decisionFrontId != nil
    }

    var title: String {
        photoset?.name ?? ""
    }

    let logger: Logger?

    private let coordinator: Coordinator
    private let fetchPhotosUseCase: FetchPhotosUseCase
    private let loadDecisionsUseCase: LoadDecisionsUseCase
    private let exportDecisionsUseCase: ExportDecisionsUseCase
    private let syncRegistry: PhotosetSyncRegistry
    private let recordLastOpenedUseCase: RecordLastOpenedUseCase

    private let photosetTask: Task<Photoset, Error>
    private lazy var photosTask = Task {
        let photoset = try await photosetTask.value
        return try await fetchPhotosUseCase.execute(id: photoset.id)
    }

    private var decisionsTask: Task<[PhotoId: Decision], Error> {
        Task {
            let photoset = try await photosetTask.value

            return try await loadDecisionsUseCase.execute(for: photoset.id)
        }
    }

    private var photoset: Photoset?
    private var photos: [Photo] = []
    private var decisions: [PhotoId: Decision] = [:]

    private var lastVisibleId: PhotoId? = nil

    @Published private var nextPendingId: PhotoId? = nil
    @Published private var decisionFrontId: PhotoId? = nil

    private var windowBoostTask: Task<Void, Never>?

    nonisolated private init(
        photosetTask: Task<Photoset, Error>,
        coordinator: Coordinator,
        fetchPhotosUseCase: FetchPhotosUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase,
        exportDecisionsUseCase: ExportDecisionsUseCase,
        syncRegistry: PhotosetSyncRegistry,
        recordLastOpenedUseCase: RecordLastOpenedUseCase,
        logger: Logger?
    ) {
        self.logger = logger
        self.photosetTask = photosetTask
        self.coordinator = coordinator
        self.fetchPhotosUseCase = fetchPhotosUseCase
        self.loadDecisionsUseCase = loadDecisionsUseCase
        self.exportDecisionsUseCase = exportDecisionsUseCase
        self.syncRegistry = syncRegistry
        self.recordLastOpenedUseCase = recordLastOpenedUseCase
    }

    nonisolated convenience init(
        id: PhotosetId,
        coordinator: Coordinator,
        fetchPhotosetUseCase: FetchPhotosetUseCase,
        fetchPhotosUseCase: FetchPhotosUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase,
        exportDecisionsUseCase: ExportDecisionsUseCase,
        syncRegistry: PhotosetSyncRegistry,
        recordLastOpenedUseCase: RecordLastOpenedUseCase,
        logger: Logger?
    ) {
        self.init(
            photosetTask: Task {
                try await fetchPhotosetUseCase.execute(id: id)
            },
            coordinator: coordinator,
            fetchPhotosUseCase: fetchPhotosUseCase,
            loadDecisionsUseCase: loadDecisionsUseCase,
            exportDecisionsUseCase: exportDecisionsUseCase,
            syncRegistry: syncRegistry,
            recordLastOpenedUseCase: recordLastOpenedUseCase,
            logger: logger
        )
    }
}


extension PhotosetDetailViewModel {
    func loadPhotos() async {
        if case .initial = state {
            state = .loading
        }

        do {
            async let photosetResult = photosetTask.value
            async let photosResult = photosTask.value
            async let decisionsResult = decisionsTask.value

            let (photoset, photos, decisions) = try await (photosetResult, photosResult, decisionsResult)

            Task {
                await recordLastOpenedUseCase.execute(id: photoset.id)
            }

            self.photoset = photoset
            self.photos = photos
            self.decisions = decisions

            recountPendingIds()

            let sync = syncRegistry.useCase(for: photoset.id)
            syncUseCase = sync
            await sync.setForeground(true)

            state = .content(photos.map { photo in
                PhotoGridCellViewModel(
                    id: photo.id,
                    imageURL: photo.url,
                    decision: decisions[photo.id] ?? .pending,
                ) { [weak self] in
                    self?.didTap(photo: photo)
                }
            })

            let photosetId = photoset.id

            export = DecisionsExport(
                filename: "\(photoset.name).json"
            ) { [weak self] in
                try await self?.exportDecisionsUseCase.execute(photosetId: photosetId) ?? Data()
            }
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
}

// MARK: View events

extension PhotosetDetailViewModel {
    func onDisappear() {
        Task { await syncUseCase?.setForeground(false) }
    }

    func didTapPrefetchButton() {
        guard let syncUseCase else {
            return
        }

        Task {
            switch syncUseCase.state {
                case .notCached:
                    await syncUseCase.start()
                case .syncing:
                    await syncUseCase.cancel()
                case .synced:
                    await syncUseCase.clear()
            }
        }
    }

    func didTapNextButton() {
        withAnimation(.easeInOut(duration: 0.25)) {
            scrollTarget = nextPendingId
        }
    }

    func didLongPressNextButton() {
        withAnimation(.easeInOut(duration: 0.25)) {
            scrollTarget = decisionFrontId
        }
    }

    func didShow(photoIds: [PhotoId]) {
        guard let last = photoIds.last else {
            return
        }

        lastVisibleId = last

        recountPendingIds()

        let visible = Set(photoIds)
        let urls = photos.filter { visible.contains($0.id) }.map(\.url)

        windowBoostTask?.cancel()
        windowBoostTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))

            guard !Task.isCancelled else {
                return
            }

            await self?.syncUseCase?.window(urls)
        }
    }
}

// MARK: Opening detail

private extension PhotosetDetailViewModel {
    func didTap(photo: Photo) {
        guard let photoset else {
            return
        }

        let startIndex = photos.firstIndex(of: photo) ?? .zero

        logger?.debug("didTap \(photo.id) → startIndex=\(startIndex) of \(photos.count)")

        coordinator.show(
            .photoViewer(
                photos: photos,
                startIndex: startIndex,
                photosetId: photoset.id
            )
        )
    }
}


private extension PhotosetDetailViewModel {
    func recountPendingIds() {
        guard let lastVisibleId else {
            return
        }

        nextPendingId = nextPendingIslandStart(after: lastVisibleId)
        decisionFrontId = computeDecisionFront(after: lastVisibleId)
    }

    func nextPendingIslandStart(after photoId: PhotoId) -> PhotoId? {
        photos
            .drop { $0.id != photoId }
            .dropFirst()
            .drop { decisions[$0.id].isUndecided }
            .drop { !decisions[$0.id].isUndecided }
            .first?
            .id
    }

    func computeDecisionFront(after photoId: PhotoId) -> PhotoId? {
        var current = nextPendingIslandStart(after: photoId)

        while let id = current,
              let next = nextPendingIslandStart(after: id) {
            current = next
        }

        return current
    }
}


private extension Decision? {
    var isUndecided: Bool {
        switch self {
            case .approved, .rejected:
                false
            case .pending, nil:
                true
        }
    }
}
