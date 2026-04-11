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
    }
}
