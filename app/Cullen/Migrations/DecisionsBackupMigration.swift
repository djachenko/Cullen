//
//  DecisionsBackupMigration.swift
//  Cullen
//
//  Снимает копию decisions/ перед прогоном остальных миграций — миграция переписывает
//  файлы на месте, и без копии откатывать её нечем. Кулдаун здесь не действует:
//  за время с прошлого снимка отбор мог уйти далеко вперёд.
//

import Foundation


final class DecisionsBackupMigration: Migration {
    let key: String? = nil

    private let backupUseCase: BackupDecisionsUseCase

    init(backupUseCase: BackupDecisionsUseCase) {
        self.backupUseCase = backupUseCase
    }

    func run() async throws {
        try await backupUseCase.execute(force: true)
    }
}
