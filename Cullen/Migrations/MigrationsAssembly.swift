//
//  MigrationsAssembly.swift
//  Cullen
//
//  Created by justin on 28/3/26.
//

import Swinject
import SwinjectAutoregistration


final class MigrationsAssembly: Assembly {
    func assemble(container: Container) {
        container.register([Migration].self) { resolver in
            [
                resolver ~> DecisionsCodableFormatFalloutMigration.self,
                resolver ~> DecisionsUrlToNameIdMigration.self,
            ]
        }

        container.autoregister(MigrationService.self, initializer: MigrationService.init)
            .inObjectScope(.container)

        container.autoregister(DecisionsUrlToNameIdMigration.self, initializer: DecisionsUrlToNameIdMigration.init)
        container.autoregister(DecisionsCodableFormatFalloutMigration.self, initializer: DecisionsCodableFormatFalloutMigration.init)
    }
}
