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
    private let syncService: ImageSyncService
    private let photosetsRepository: PhotosetsRepository

    private var useCases: [PhotosetId: PhotosetSyncUseCase] = [:]

    nonisolated init(syncService: ImageSyncService, photosetsRepository: PhotosetsRepository) {
        self.syncService = syncService
        self.photosetsRepository = photosetsRepository
    }

    func useCase(for id: PhotosetId) -> PhotosetSyncUseCase {
        if let existing = useCases[id] {
            return existing
        }

        let useCase = PhotosetSyncUseCase(
            photosetId: id,
            syncService: syncService,
            photosetsRepository: photosetsRepository
        )

        useCases[id] = useCase

        return useCase
    }
}
