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

        container.autoregister(LastOpenedRepository.self, initializer: UserDefaultsLastOpenedRepository.init)
            .inObjectScope(.container)

        container.autoregister(DesiredSyncStore.self, initializer: UserDefaultsDesiredSyncStore.init)
            .inObjectScope(.container)

        container.register(KingfisherImageSyncService.self) { resolver in
            KingfisherImageSyncService(
                downloader: KingfisherManager.shared.downloader,
                cache: resolver ~> ImageCache.self,
                maxInFlight: 4 // matches KingfisherConfiguration.httpMaximumConnectionsPerHost
            )
        }
        .inObjectScope(.container)

        container.register(ImageDownloadService.self) { $0 ~> KingfisherImageSyncService.self }
        container.register(ImageCacheService.self) { $0 ~> KingfisherImageSyncService.self }

        container.autoregister(AppPreferences.init)
            .inObjectScope(.container)
            .implements(PhotosetFeedPreferences.self)
            .implements(SigningExpirationServicePreferences.self)
    }
}
