//
//  DecisionsBackupMigrationTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


struct DecisionsBackupMigrationTests {
    @Test
    func takesSnapshotIgnoringCooldown() async throws {
        let useCase = SpyBackupDecisionsUseCase()
        let migration = DecisionsBackupMigration(backupUseCase: useCase)

        try await migration.run()

        #expect(useCase.forcedCalls == [true])
    }

    // key = nil означает «каждый запуск»: снимок должен предшествовать любой
    // миграции, а не сниматься однажды и больше никогда.
    @Test
    func runsOnEveryLaunch() {
        let migration = DecisionsBackupMigration(backupUseCase: SpyBackupDecisionsUseCase())

        #expect(migration.key == nil)
    }
}

private final class SpyBackupDecisionsUseCase: BackupDecisionsUseCase {
    private(set) var forcedCalls: [Bool] = []

    func execute(force: Bool) async throws {
        forcedCalls.append(force)
    }
}
