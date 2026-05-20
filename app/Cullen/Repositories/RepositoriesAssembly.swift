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

        container.autoregister(ImageCacheService.self, initializer: KingfisherImageCacheService.init)
            .inObjectScope(.container)
    }
}
