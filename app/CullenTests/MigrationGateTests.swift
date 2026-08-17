//
//  MigrationGateTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


@MainActor
struct MigrationGateTests {
    @Test
    func staysClosedBeforeOpen() throws {
        let gate = MigrationGate(migrationService: service(migrations: []))

        #expect(gate.isReady == false)
    }

    @Test
    func opensAfterMigrationsFinish() async throws {
        let migration = SpyMigration()
        let gate = MigrationGate(migrationService: service(migrations: [migration]))

        await gate.open()

        #expect(gate.isReady)
        #expect(migration.runs == 1)
    }

    // Суть фикса: пока миграция работает, фид показывать нельзя — иначе
    // DecisionsUseCaseImpl успеет закешировать домигрированные решения (ADR-05).
    @Test
    func keepsGateClosedWhileMigrationRuns() async throws {
        let migration = ObservingMigration()
        let gate = MigrationGate(migrationService: service(migrations: [migration]))
        migration.gate = gate

        await gate.open()

        #expect(migration.readyDuringRun == false)
        #expect(gate.isReady)
    }

    @Test
    func doesNotRerunMigrationsOnSecondOpen() async throws {
        let migration = SpyMigration()
        let gate = MigrationGate(migrationService: service(migrations: [migration]))

        await gate.open()
        await gate.open()

        #expect(migration.runs == 1)
    }

    // Упавшая миграция не должна оставить приложение на бесконечном спиннере.
    @Test
    func opensEvenWhenMigrationFails() async throws {
        let gate = MigrationGate(migrationService: service(migrations: [FailingMigration()]))

        await gate.open()

        #expect(gate.isReady)
    }
}

private extension MigrationGateTests {
    func service(migrations: [Migration]) -> MigrationService {
        MigrationService(
            migrations: migrations,
            userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard
        )
    }
}

private final class SpyMigration: Migration {
    let key: String? = nil

    private(set) var runs = 0

    func run() async throws {
        runs += 1
    }
}

private final class ObservingMigration: Migration {
    let key: String? = nil

    var gate: MigrationGate?
    private(set) var readyDuringRun: Bool?

    func run() async throws {
        readyDuringRun = await gate?.isReady
    }
}

private final class FailingMigration: Migration {
    let key: String? = nil

    func run() async throws {
        throw CocoaError(.fileNoSuchFile)
    }
}
