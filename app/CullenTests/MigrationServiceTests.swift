//
//  MigrationServiceTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


struct MigrationServiceTests {
    @Test
    func runsKeyedMigrationOnce() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let migration = SpyMigration(key: "decisions_remove_prefix_migration")

        await MigrationService(migrations: [migration], userDefaults: defaults).runMigrations()
        await MigrationService(migrations: [migration], userDefaults: defaults).runMigrations()

        #expect(migration.runs == 1)
        #expect(defaults.bool(forKey: "decisions_remove_prefix_migration"))
    }

    // nil означает «каждый запуск» — на этом держатся идемпотентные миграции.
    @Test
    func runsUnkeyedMigrationEveryTime() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let migration = SpyMigration(key: nil)

        await MigrationService(migrations: [migration], userDefaults: defaults).runMigrations()
        await MigrationService(migrations: [migration], userDefaults: defaults).runMigrations()

        #expect(migration.runs == 2)
    }

    @Test
    func skipsMigrationAlreadyMarkedDone() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        defaults.set(true, forKey: "already_done")
        let migration = SpyMigration(key: "already_done")

        await MigrationService(migrations: [migration], userDefaults: defaults).runMigrations()

        #expect(migration.runs == 0)
    }

    // Упавшая миграция не должна помечаться выполненной, иначе повтора не будет никогда.
    @Test
    func keepsFailedMigrationUnmarked() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let migration = SpyMigration(key: "failing", error: MigrationTestError.boom)

        await MigrationService(migrations: [migration], userDefaults: defaults).runMigrations()

        #expect(migration.runs == 1)
        #expect(defaults.bool(forKey: "failing") == false)
    }

    @Test
    func continuesAfterFailure() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let failing = SpyMigration(key: nil, error: MigrationTestError.boom)
        let following = SpyMigration(key: nil)

        await MigrationService(migrations: [failing, following], userDefaults: defaults).runMigrations()

        #expect(following.runs == 1)
    }

    // Порядок важен: снимок decisions обязан лечь до того, как кто-то начнёт писать.
    @Test
    func runsMigrationsInOrder() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let order = OrderRecorder()
        let first = SpyMigration(key: nil, name: "first", recorder: order)
        let second = SpyMigration(key: nil, name: "second", recorder: order)

        await MigrationService(migrations: [first, second], userDefaults: defaults).runMigrations()

        #expect(order.names == ["first", "second"])
    }
}

private enum MigrationTestError: Error {
    case boom
}

private final class OrderRecorder {
    private(set) var names: [String] = []

    func record(_ name: String) {
        names.append(name)
    }
}

private final class SpyMigration: Migration {
    let key: String?

    private(set) var runs = 0

    private let error: Error?
    private let name: String
    private let recorder: OrderRecorder?

    init(key: String?, error: Error? = nil, name: String = "", recorder: OrderRecorder? = nil) {
        self.key = key
        self.error = error
        self.name = name
        self.recorder = recorder
    }

    func run() async throws {
        runs += 1
        recorder?.record(name)

        if let error {
            throw error
        }
    }
}
