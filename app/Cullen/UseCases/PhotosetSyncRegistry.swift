//
//  PhotosetSyncRegistry.swift
//  Cullen
//
//  Domain - vends one shared PhotosetSyncUseCase per PhotosetId.
//  Swinject can't key an object scope by a runtime value, so this small
//  registry does it. Holds them WEAKLY: a running sync lives in the download
//  service (which owns the tasks), not in the use case, so a use case may
//  deallocate when its screens are gone and be rebuilt (state reconstructed
//  from the cache) on the next visit.
//


private final class WeakUseCase {
    weak var value: PhotosetSyncUseCase?

    init(_ value: PhotosetSyncUseCase) {
        self.value = value
    }
}


@MainActor
final class PhotosetSyncRegistry {
    private let downloadService: ImageDownloadService
    private let cacheService: ImageCacheService
    private let photosetsRepository: PhotosetsRepository
    private let desiredStore: DesiredSyncStore

    private var useCases: [PhotosetId: WeakUseCase] = [:]

    nonisolated init(
        downloadService: ImageDownloadService,
        cacheService: ImageCacheService,
        photosetsRepository: PhotosetsRepository,
        desiredStore: DesiredSyncStore
    ) {
        self.downloadService = downloadService
        self.cacheService = cacheService
        self.photosetsRepository = photosetsRepository
        self.desiredStore = desiredStore
    }

    func useCase(for id: PhotosetId) -> PhotosetSyncUseCase {
        if let existing = useCases[id]?.value {
            return existing
        }

        let useCase = PhotosetSyncUseCase(
            photosetId: id,
            downloadService: downloadService,
            cacheService: cacheService,
            photosetsRepository: photosetsRepository,
            desiredStore: desiredStore
        )

        useCases[id] = WeakUseCase(useCase)

        return useCase
    }

    // Resume every photoset the user marked for offline on the previous run.
    // Each start() enqueues into the download service and then the use case may
    // be released — the download lives on without it.
    func resumeDesired() async {
        await desiredStore.all().forEach { id in
            Task { await useCase(for: id).start() }
        }
    }
}
