//
//  DecisionsBackupRepository.swift
//  Cullen
//
//  Created by justin on 11/8/26.
//

import Foundation


protocol DecisionsBackupRepository {
    /// Новые первыми.
    func backups() async throws -> [DecisionsBackup]

    func createBackup(id: String) async throws

    func deleteBackup(id: String) async throws
}
