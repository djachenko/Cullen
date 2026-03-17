//
//  AppAssembly.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import Swinject
import SwinjectAutoregistration


final class AppAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(AppCoordinator.self, initializer: AppCoordinator.init)
            .implements(Coordinator.self)
            .inObjectScope(.container)

        container.autoregister(
            AppCoordinatorView.self,
            argument: AppDestination.self,
            initializer: AppCoordinatorView.init
        )

        container.register(Resolver.self) { $0 }
            .inObjectScope(.weak)
    }
}
