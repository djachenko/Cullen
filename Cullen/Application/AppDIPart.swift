//
//  AppAssembly.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import Swinject
import SwinjectAutoregistration


final class AppAssembly: Assembly {
    private var currentCoordinator: AppCoordinator?

    func assemble(container: Container) {
        container.register(Coordinator.self) {  resover -> Coordinator in
            return self.currentCoordinator ?? (resover ~> MockCoordinator.self)
        }

        container.autoregister(
            AppCoordinator.self,
            argument: AppDestination.self,
            initializer: AppCoordinator.init
        )
        .inObjectScope(.weak)
        .initCompleted {
            self.currentCoordinator = $1
        }

        container.autoregister(MockCoordinator.self, initializer: MockCoordinator.init)
            .inObjectScope(.weak)

        container.register(AppCoordinatorView.self) { (r, root: AppDestination) in
            AppCoordinatorView(
                coordinator: r ~> (AppCoordinator.self, argument: root)
            )
        }

        container.register(Resolver.self) { $0 }
            .inObjectScope(.weak)
    }
}
