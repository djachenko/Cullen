//
//  MigrationGate.swift
//  Cullen
//
//  Держит UI закрытым, пока миграции не отработали. Инвариант ADR-05: кеш решений
//  не инвалидируется, потому что до первого экрана его некому наполнить — а это
//  верно ровно до тех пор, пока фид не показывают раньше миграций.
//

import Foundation
import Observation


@MainActor
@Observable
final class MigrationGate {
    private(set) var isReady = false

    private let migrationService: MigrationService

    init(migrationService: MigrationService) {
        self.migrationService = migrationService
    }

    // Повторный вызов из .task при пересоздании сцены не должен гонять миграции заново.
    func open() async {
        guard !isReady else {
            return
        }

        await migrationService.runMigrations()

        isReady = true
    }
}
