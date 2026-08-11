//
//  BackupDecisionsUseCaseTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


struct BackupDecisionsUseCaseTests {
    private static let cooldown: TimeInterval = 6 * 60 * 60

    @Test
    func createsBackupWhenNoneExist() async throws {
        let repository = FakeDecisionsBackupRepository()

        try await BackupDecisionsUseCaseImpl(backupRepository: repository).execute(force: false)

        #expect(repository.created.count == 1)
    }

    // Граница включающая: ровно кулдаун уже считается истёкшим.
    @Test(arguments: [
        (age: cooldown / 2, expected: 0),
        (age: cooldown - 1, expected: 0),
        (age: cooldown, expected: 1),
        (age: cooldown + 1, expected: 1),
        (age: cooldown * 10, expected: 1),
    ])
    func honoursCooldown(age: TimeInterval, expected: Int) async throws {
        let latest = DecisionsBackup(id: "latest", date: Date().addingTimeInterval(-age))
        let repository = FakeDecisionsBackupRepository(stored: [latest])

        try await BackupDecisionsUseCaseImpl(backupRepository: repository).execute(force: false)

        #expect(repository.created.count == expected)
    }

    // Ради этого force и существует: перед миграциями снимок нужен всегда,
    // сколько бы времени ни прошло с предыдущего.
    @Test(arguments: [0, cooldown / 2, cooldown * 10])
    func forceIgnoresCooldown(age: TimeInterval) async throws {
        let latest = DecisionsBackup(id: "latest", date: Date().addingTimeInterval(-age))
        let repository = FakeDecisionsBackupRepository(stored: [latest])

        try await BackupDecisionsUseCaseImpl(backupRepository: repository).execute(force: true)

        #expect(repository.created.count == 1)
    }

    @Test(arguments: [
        (existing: 0, deleted: 0),
        (existing: 8, deleted: 0),
        (existing: 9, deleted: 0),
        (existing: 10, deleted: 1),
        (existing: 15, deleted: 6),
    ])
    func keepsTenMostRecentBackups(existing: Int, deleted: Int) async throws {
        let stored = (0..<existing).map { index in
            DecisionsBackup(id: "backup-\(index)", date: Date().addingTimeInterval(-Double(index + 1) * 60))
        }
        let repository = FakeDecisionsBackupRepository(stored: stored)

        try await BackupDecisionsUseCaseImpl(backupRepository: repository).execute(force: true)

        #expect(repository.deleted.count == deleted)
    }

    // Удаляются именно самые старые — свежий снимок и девять предыдущих остаются.
    @Test
    func prunesOldestFirst() async throws {
        let stored = (0..<12).map { index in
            DecisionsBackup(id: "backup-\(index)", date: Date().addingTimeInterval(-Double(index + 1) * 60))
        }
        let repository = FakeDecisionsBackupRepository(stored: stored)

        try await BackupDecisionsUseCaseImpl(backupRepository: repository).execute(force: true)

        #expect(repository.deleted == ["backup-9", "backup-10", "backup-11"])
    }
}
