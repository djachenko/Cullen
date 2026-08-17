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
            // Снимок decisions идёт первым: forEach последовательный, так что остальные
            // получают данные уже после того, как копия легла на диск.
            [
                resolver ~> DecisionsBackupMigration.self,
                resolver ~> DecisionsCodableFormatFalloutMigration.self,
                resolver ~> DecisionsUrlToNameIdMigration.self,
                resolver ~> DecisionsRemoveSuffixMigration.self,
            ]
        }

        container.autoregister(MigrationService.init)
            .inObjectScope(.container)

        container.autoregister(DecisionsBackupMigration.init)
        container.autoregister(DecisionsUrlToNameIdMigration.init)
        container.autoregister(DecisionsCodableFormatFalloutMigration.init)
        container.autoregister(DecisionsRemoveSuffixMigration.init)
    }
}
