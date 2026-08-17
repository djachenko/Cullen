//
//  PhotosetDetailViewModel.swift
//  Cullen
//
//  Presentation Layer - Photoset Detail ViewModel
//

import Foundation
import SwiftUI
import Combine

enum SyncState {
    case unknown // baseline ещё не посчитан: «не знаем», а не «ноль»
    case online
    case partial(progress: Double)
    case downloading(progress: Double)
    case downloaded
}


@MainActor
final class PhotosetDetailViewModel: ObservableObject {
    @Published var state: PhotosetDetailState = .initial
    @Published var aspectRatio: Double = 3.0 / 2.0
    @Published var export: DecisionsExport?
    @Published var scrollTarget: PhotoId? = nil

    @Published var filter: Set<Decision> = Set(Decision.allCases) {
        didSet {
            guard case .content = state else {
                return
            }

            state = .content(makeContent())

            recountPendingIds()
        }
    }

    var showNextButton: Bool {
        nextPendingId != nil || decisionFrontId != nil
    }

    var title: String {
        photoset?.name ?? ""
    }

    var syncState: SyncState {
        guard let progress = syncUseCase.progress else {
            return .unknown
        }

        return if progress == 1 {
            .downloaded
        } else if syncUseCase.isSyncing {
            .downloading(progress: progress)
        } else if progress == 0 {
            .online
        } else {
            .partial(progress: progress)
        }
    }

    let logger: Logger?

    private let coordinator: Coordinator
    private let fetchPhotosUseCase: FetchPhotosUseCase
    private let loadDecisionsUseCase: LoadDecisionsUseCase
    private let exportDecisionsUseCase: ExportDecisionsUseCase
    private let syncUseCase: PhotosetSyncUseCase
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
        syncUseCase: PhotosetSyncUseCase,
        recordLastOpenedUseCase: RecordLastOpenedUseCase,
        logger: Logger?
    ) {
        self.logger = logger
        self.photosetTask = photosetTask
        self.coordinator = coordinator
        self.fetchPhotosUseCase = fetchPhotosUseCase
        self.loadDecisionsUseCase = loadDecisionsUseCase
        self.exportDecisionsUseCase = exportDecisionsUseCase
        self.syncUseCase = syncUseCase
        self.recordLastOpenedUseCase = recordLastOpenedUseCase
    }

    nonisolated convenience init(
        id: PhotosetId,
        coordinator: Coordinator,
        fetchPhotosetUseCase: FetchPhotosetUseCase,
        fetchPhotosUseCase: FetchPhotosUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase,
        exportDecisionsUseCase: ExportDecisionsUseCase,
        syncUseCase: PhotosetSyncUseCase,
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
            syncUseCase: syncUseCase,
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

            await syncUseCase.loadCacheState()
            await syncUseCase.set(isForeground: true)

            state = .content(makeContent())

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
        Task {
            await syncUseCase.set(isForeground: false)
        }
    }

    func didTapPrefetchButton() {
        Task {
            switch syncState {
                case .downloaded:
                    await syncUseCase.clear()
                case .downloading:
                    await syncUseCase.cancel()
                case .partial, .online, .unknown:
                    await syncUseCase.startOfflineSync()
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

            await self?.syncUseCase.window(urls)
        }
    }
}

// MARK: Building content

private extension PhotosetDetailViewModel {
    var filteredPhotos: [Photo] {
        photos.filter { filter.contains(decisions[$0.id] ?? .pending) }
    }

    func makeContent() -> PhotosetDetailContent {
        filteredPhotos.map { photo in
            PhotoGridCellViewModel(
                id: photo.id,
                imageURL: photo.url,
                decision: decisions[photo.id] ?? .pending,
            ) { [weak self] in
                self?.didTap(photo: photo)
            }
        }
    }
}

// MARK: Opening detail

private extension PhotosetDetailViewModel {
    func didTap(photo: Photo) {
        guard let photoset else {
            return
        }

        let photos = filteredPhotos
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

        let photos = filteredPhotos

        nextPendingId = nextPendingIslandStart(after: lastVisibleId, in: photos)
        decisionFrontId = computeDecisionFront(after: lastVisibleId, in: photos)
    }

    func nextPendingIslandStart(after photoId: PhotoId, in photos: [Photo]) -> PhotoId? {
        photos
            .drop { $0.id != photoId }
            .dropFirst()
            .drop { decisions[$0.id].isUndecided }
            .drop { !decisions[$0.id].isUndecided }
            .first?
            .id
    }

    func computeDecisionFront(after photoId: PhotoId, in photos: [Photo]) -> PhotoId? {
        var current = nextPendingIslandStart(after: photoId, in: photos)

        while let id = current,
              let next = nextPendingIslandStart(after: id, in: photos) {
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
