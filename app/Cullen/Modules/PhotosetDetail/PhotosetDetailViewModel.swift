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
    @Published var nextPendingId: PhotoId? = nil
    @Published var prefetchState: PhotosetDetailPrefetchState = .notCached

    var title: String {
        photoset?.name ?? ""
    }

    let logger: Logger?

    private let coordinator: Coordinator
    private let fetchPhotosUseCase: FetchPhotosUseCase
    private let loadDecisionsUseCase: LoadDecisionsUseCase
    private let exportDecisionsUseCase: ExportDecisionsUseCase
    private let cacheUseCase: CacheUseCase
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

    private var prefetchTask: Task<Void, Never>?

    nonisolated private init(
        photosetTask: Task<Photoset, Error>,
        coordinator: Coordinator,
        fetchPhotosUseCase: FetchPhotosUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase,
        exportDecisionsUseCase: ExportDecisionsUseCase,
        cacheUseCase: CacheUseCase,
        recordLastOpenedUseCase: RecordLastOpenedUseCase,
        logger: Logger?
    ) {
        self.logger = logger
        self.photosetTask = photosetTask
        self.coordinator = coordinator
        self.fetchPhotosUseCase = fetchPhotosUseCase
        self.loadDecisionsUseCase = loadDecisionsUseCase
        self.exportDecisionsUseCase = exportDecisionsUseCase
        self.cacheUseCase = cacheUseCase
        self.recordLastOpenedUseCase = recordLastOpenedUseCase
    }

    nonisolated convenience init(
        id: PhotosetId,
        coordinator: Coordinator,
        fetchPhotosetUseCase: FetchPhotosetUseCase,
        fetchPhotosUseCase: FetchPhotosUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase,
        exportDecisionsUseCase: ExportDecisionsUseCase,
        cacheUseCase: CacheUseCase,
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
            cacheUseCase: cacheUseCase,
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

            prefetchState = await countPrefetchState()

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
        cancelPrefetch()
    }

    func didTapPrefetchButton() {
        switch prefetchState {
            case .notCached, .partial:
                startPrefetch()
            case .full:
                clearCache()
            case .prefetching:
                cancelPrefetch()
        }
    }

    func didShow(photoIds: [PhotoId]) {
        guard let last = photoIds.last else {
            return
        }

        nextPendingId = photos
            .drop { $0.id <= last }
            .drop { decisions[$0.id].isUndecided }
            .drop { !decisions[$0.id].isUndecided }
            .first?
            .id

        logger?.debug("didShow last=\(last) visible=\(photoIds.count) → nextPendingId=\(String(describing: nextPendingId))")
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

// MARK: Handle cache workflow

private extension PhotosetDetailViewModel {
    func startPrefetch() {
        guard let photosetId = photoset?.id else {
            return
        }

        prefetchTask = Task { [weak self] in
            guard let self,
                  let stream = try? await cacheUseCase.prefetch(photoset: photosetId) else {
                return
            }

            for await event in stream {
                switch event {
                    case .progress(let done, let total):
                        let progress = Double(done) / Double(total)
                        prefetchState = .prefetching(progress: progress)
                    case .finished:
                        prefetchState = await countPrefetchState()
                }
            }
        }
    }

    func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil

        Task { [weak self] in
            guard let self else {
                return
            }

            prefetchState = await countPrefetchState()
        }
    }

    func clearCache() {
        guard let photosetId = photoset?.id else {
            return
        }

        Task { [weak self] in
            guard let self else {
                return
            }

            try? await cacheUseCase.removeFromCache(photoset: photosetId)
            prefetchState = await countPrefetchState()
        }
    }
}


private extension PhotosetDetailViewModel {
    func countPrefetchState() async -> PhotosetDetailPrefetchState {
        if let photosetId = photoset?.id,
           let ratio = try? await cacheUseCase.cacheRatio(photoset: photosetId) {
            PhotosetDetailPrefetchState(ratio: ratio)
        } else {
            .notCached
        }
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


private extension PhotosetDetailPrefetchState {
    init(ratio: Double) {
        self = switch ratio {
            case 0:
                .notCached
            case 1:
                .full
            default:
                .partial(ratio: ratio)
        }
    }
}
