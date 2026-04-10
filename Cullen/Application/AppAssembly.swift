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
        container.autoregister(AppCoordinator.init)
            .implements(Coordinator.self)
            .inObjectScope(.container)

        container.autoregister(AppCoordinatorView.init)
    }
}
