//
//  BackupDecisionsUseCase.swift
//  Cullen
//
//  Created by justin on 11/8/26.
//

import Foundation


protocol BackupDecisionsUseCase {
    /// `force` игнорирует кулдаун — для снимка непосредственно перед миграциями.
    func execute(force: Bool) async throws
}

final class BackupDecisionsUseCaseImpl {
    private enum Constants {
        static let cooldown: TimeInterval = 6 * 60 * 60
        static let keptBackups = 10
    }

    private let backupRepository: DecisionsBackupRepository

    init(backupRepository: DecisionsBackupRepository) {
        self.backupRepository = backupRepository
    }
}

extension BackupDecisionsUseCaseImpl: BackupDecisionsUseCase {
    func execute(force: Bool) async throws {
        // Кулдаун считается по самому свежему снимку, а не по отдельной метке в UserDefaults:
        // если папку почистили руками, копия снимется сразу, а не по истечении таймера.
        let latest = try await backupRepository.backups().first

        guard force || isExpired(latest) else {
            return
        }

        try await backupRepository.createBackup(id: stamp())
        try await prune()
    }
}

private extension BackupDecisionsUseCaseImpl {
    func isExpired(_ backup: DecisionsBackup?) -> Bool {
        guard let backup else {
            return true
        }

        return Date().timeIntervalSince(backup.date) >= Constants.cooldown
    }

    func stamp() -> String {
        Date().formatted(.iso8601.dateSeparator(.omitted).timeSeparator(.omitted))
    }

    func prune() async throws {
        let outdated = try await backupRepository
            .backups()
            .dropFirst(Constants.keptBackups)

        for backup in outdated {
            try await backupRepository.deleteBackup(id: backup.id)
        }
    }
}
