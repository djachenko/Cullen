//
//  PhotosetSyncRegistry.swift
//  Cullen
//
//  Domain - vends one shared PhotosetSyncUseCase per PhotosetId.
//  Swinject can't key an object scope by a runtime value, so this small
//  registry does it. Container-scoped: retaining the use cases here is what
//  keeps a sync alive after its screen is gone.
//


@MainActor
final class PhotosetSyncRegistry {
    private let downloadService: ImageDownloadService
    private let cacheService: ImageCacheService
    private let photosetsRepository: PhotosetsRepository
    private let desiredStore: DesiredSyncStore

    private var useCases: [PhotosetId: PhotosetSyncUseCase] = [:]

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
        if let existing = useCases[id] {
            return existing
        }

        let useCase = PhotosetSyncUseCase(
            photosetId: id,
            downloadService: downloadService,
            cacheService: cacheService,
            photosetsRepository: photosetsRepository,
            desiredStore: desiredStore
        )

        useCases[id] = useCase

        return useCase
    }

    // Resume every photoset the user marked for offline on the previous run.
    func resumeDesired() async {
        for id in await desiredStore.all() {
            Task { await useCase(for: id).start() }
        }
    }
}
