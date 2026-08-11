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

        // Не autoregister: гейт изолирован на MainActor, и потеря изоляции в
        // Swift 6 mode станет ошибкой. Резолвится он из App.init, то есть с main.
        container.register(MigrationGate.self) { resolver in
            MainActor.assumeIsolated {
                MigrationGate(migrationService: resolver ~> MigrationService.self)
            }
        }
        .inObjectScope(.container)
    }
}
