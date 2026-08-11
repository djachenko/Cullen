//
//  FakeDecisionsBackupRepository.swift
//  CullenTests
//

import Foundation
@testable import Cullen


final class FakeDecisionsBackupRepository: DecisionsBackupRepository {
    private(set) var created: [String] = []
    private(set) var deleted: [String] = []

    var stored: [DecisionsBackup]

    init(stored: [DecisionsBackup] = []) {
        self.stored = stored
    }

    func backups() async throws -> [DecisionsBackup] {
        stored.sorted { $0.date > $1.date }
    }

    func createBackup(id: String) async throws {
        created.append(id)
        stored.append(DecisionsBackup(id: id, date: Date()))
    }

    func deleteBackup(id: String) async throws {
        deleted.append(id)
        stored.removeAll { $0.id == id }
    }
}
