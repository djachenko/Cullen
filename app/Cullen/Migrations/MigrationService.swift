//
//  MigrationService.swift
//  Cullen
//
//  Created by justin on 28/3/26.
//

import Foundation


protocol Migration {
    /// nil = запускать каждый раз
    var key: String? { get }

    func run() async throws
}

final class MigrationService {
    private let migrations: [any Migration]
    private let userDefaults: UserDefaults

    init(migrations: [Migration], userDefaults: UserDefaults) {
        self.migrations = migrations
        self.userDefaults = userDefaults
    }

    func runMigrations() async {
//        TODO: make asyncForEach
        for migration in migrations {
            let shouldRun = migration.key.map {
                !userDefaults.bool(forKey: $0)
            } ?? true

            guard shouldRun else {
                continue
            }

            do {
                try await migration.run()

                if let key = migration.key {
                    userDefaults.set(true, forKey: key)
                }
            } catch {
                print("[MigrationService] Migration \(migration.key ?? "(always-run)") failed: \(error)")
            }
        }
    }
}

