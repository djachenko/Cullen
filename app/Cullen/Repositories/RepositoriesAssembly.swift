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
            .inObjectScope(.container)
            .implements(SyncEventPublisher.self)
            .implements(SyncEventSource.self)

        container.autoregister(ImageCacheServiceImpl.init)
            .implements(ImageCacheService.self)
            .implements(ImageCacheDelegate.self)
            .inObjectScope(.container)

        container.autoregister(ImageDownloadService.self, initializer: ImageDownloadServiceImpl.init)
            .inObjectScope(.container)

        container.autoregister(AppPreferences.init)
            .inObjectScope(.container)
            .implements(PhotosetFeedPreferences.self)
            .implements(SigningExpirationServicePreferences.self)
    }
}
