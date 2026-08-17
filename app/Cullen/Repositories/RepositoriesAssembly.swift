//
//  RepositoriesAssembly.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Kingfisher
import Swinject
import SwinjectAutoregistration


final class RepositoriesAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(PhotosetsRepository.self, initializer: JsonPhotosRepository.init)
            .inObjectScope(.container)

        container.autoregister(DecisionsRepository.self, initializer: JsonDecisionsRepository.init)
            .inObjectScope(.container)

        container.autoregister(DecisionsBackupRepository.self, initializer: FileDecisionsBackupRepository.init)
            .inObjectScope(.container)

        container.autoregister(LastOpenedRepository.self, initializer: UserDefaultsLastOpenedRepository.init)
            .inObjectScope(.container)

        container.autoregister(DesiredSyncStore.self, initializer: UserDefaultsDesiredSyncStore.init)
            .inObjectScope(.container)

        container.autoregister(CachedRatioStore.self, initializer: UserDefaultsCachedRatioStore.init)
            .inObjectScope(.container)

        container.register(SyncEventHub.self) { _ in
            SyncEventHub()
        }
        .inObjectScope(.container)
        .implements(SyncEventPublisher.self)
        .implements(SyncEventSource.self)

        // Вешает себя делегатом кэша в init, поэтому его резолвят на старте —
        // иначе записи от листания ленты потерялись бы до первого фотосета.
        container.autoregister(ImageCacheService.self, initializer: ImageCacheServiceImpl.init)
            .inObjectScope(.container)

        container.register(ImageDownloadService.self) { resolver in
            ImageDownloadServiceImpl(
                manager: KingfisherManager.shared,
                cacheService: resolver ~> ImageCacheService.self,
                publisher: resolver ~> SyncEventPublisher.self,
                maxInFlight: 4 // matches KingfisherConfiguration.httpMaximumConnectionsPerHost
            )
        }
        .inObjectScope(.container)

        container.autoregister(AppPreferences.init)
            .inObjectScope(.container)
            .implements(PhotosetFeedPreferences.self)
            .implements(SigningExpirationServicePreferences.self)
    }
}
