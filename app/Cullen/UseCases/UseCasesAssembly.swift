//
//  UseCasesAssembly.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Swinject
import SwinjectAutoregistration


final class UseCasesAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(FetchPhotosetsUseCase.self, initializer: FetchPhotosetsUseCaseImpl.init)
        container.autoregister(SortPhotosetsUseCase.self, initializer: SortPhotosetsUseCaseImpl.init)
        container.autoregister(RecordLastOpenedUseCase.self, initializer: RecordLastOpenedUseCaseImpl.init)
        container.autoregister(FetchPhotosetUseCase.self, initializer: FetchPhotosetUseCaseImpl.init)
        container.autoregister(GetPhotosetStatisticsUseCase.self, initializer: GetPhotosetStatisticsUseCaseImpl.init)
        container.autoregister(FetchPhotosUseCase.self, initializer: FetchPhotosUseCaseImpl.init)
        container.autoregister(ExportDecisionsUseCase.self, initializer: ExportDecisionsUseCaseImpl.init)
        container.autoregister(DecisionsStatsUseCase.self, initializer: DecisionsStatsUseCaseImpl.init)
        container.autoregister(ExportLogsUseCase.self, initializer: ExportLogsUseCaseImpl.init)

        container.autoregister(DecisionsUseCaseImpl.init)
            .inObjectScope(.container) // shared state: decisions cache is shared across screens
            .implements(SaveDecisionUseCase.self)
            .implements(LoadDecisionsUseCase.self)

        container.register(PhotosetSyncRegistry.self) { resolver in
            PhotosetSyncRegistry(
                downloadService: resolver ~> ImageDownloadService.self,
                cacheService: resolver ~> ImageCacheService.self,
                photosetsRepository: resolver ~> PhotosetsRepository.self,
                desiredStore: resolver ~> DesiredSyncStore.self
            )
        }
        .inObjectScope(.container) // one shared sync use case per photoset, kept alive here
    }
}
