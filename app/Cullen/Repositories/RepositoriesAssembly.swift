//
//  RepositoriesAssembly.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Swinject
import SwinjectAutoregistration


final class RepositoriesAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(PhotosetsRepository.self, initializer: JsonPhotosRepository.init)
            .inObjectScope(.container)

        container.autoregister(DecisionsRepository.self, initializer: JsonDecisionsRepository.init)
            .inObjectScope(.container)

        container.autoregister(LastOpenedRepository.self, initializer: UserDefaultsLastOpenedRepository.init)
            .inObjectScope(.container)

        container.autoregister(DesiredSyncStore.self, initializer: UserDefaultsDesiredSyncStore.init)
            .inObjectScope(.container)

        container.autoregister(SyncEventHub.init)
            .implements(SyncEventPublisher.self)
            .implements(SyncEventSource.self)
            .inObjectScope(.container)

        container.autoregister(ImageCacheService.self, initializer: ImageCacheServiceImpl.init)
            .implements(ImageCacheDelegate.self)
            .inObjectScope(.container)

        container.autoregister(ImageDownloadServiceImpl.init)

        container.register(ImageDownloadService.self) { resolver in
            resolver ~> (
                ImageDownloadServiceImpl.self,
                with: ImageDownloadServiceImpl.Limits(
                    // Совпадает с KingfisherConfiguration.httpMaximumConnectionsPerHost.
                    maxInFlight: 4,
                    maxAttempts: 3
                )
            )
        }
        .inObjectScope(.container)

        container.autoregister(AppPreferences.init)
            .inObjectScope(.container)
            .implements(PhotosetFeedPreferences.self)
            .implements(SigningExpirationServicePreferences.self)
    }
}
