//
//  FileDecisionsBackupRepository.swift
//  Cullen
//
//  Created by justin on 11/8/26.
//

import Foundation


final class FileDecisionsBackupRepository {
    private enum Constants {
        static let directoryName = "Cullen"
        static let decisions     = "decisions"
        static let backups       = "backups"
    }

    private let fileManager: FileManager
    private let decisionsDirectory: URL
    private let backupsDirectory: URL

    init(fileManager: FileManager) {
        self.fileManager = fileManager

        let root = fileManager
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appending(component: Constants.directoryName)

        self.decisionsDirectory = root.appending(component: Constants.decisions)
        self.backupsDirectory = root.appending(component: Constants.backups)
    }
}

extension FileDecisionsBackupRepository: DecisionsBackupRepository {
    func backups() async throws -> [DecisionsBackup] {
        guard fileManager.fileExists(atPath: backupsDirectory.path()) else {
            return []
        }

        return try fileManager
            .contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: [.creationDateKey])
            .compactMap { url in
                try url.resourceValues(forKeys: [.creationDateKey])
                    .creationDate
                    .map { DecisionsBackup(id: url.lastPathComponent, date: $0) }
            }
            .sorted { $0.date > $1.date }
    }

    func createBackup(id: String) async throws {
        guard fileManager.fileExists(atPath: decisionsDirectory.path()) else {
            return
        }

        let destination = backupsDirectory.appending(component: id)

        // Метка секундная: старт и премиграционный прогон попадают в одну и ту же.
        guard !fileManager.fileExists(atPath: destination.path()) else {
            return
        }

        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        try fileManager.copyItem(at: decisionsDirectory, to: destination)

        // copyItem переносит атрибуты источника: без этого у всех снимков стоит дата
        // создания decisions/, и сортировка по возрасту становится произвольной.
        try fileManager.setAttributes([.creationDate: Date()], ofItemAtPath: destination.path())
    }

    func deleteBackup(id: String) async throws {
        try fileManager.removeItem(at: backupsDirectory.appending(component: id))
    }
}
