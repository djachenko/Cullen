//
//  FileDecisionsBackupRepositoryTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


struct FileDecisionsBackupRepositoryTests {
    @Test
    func copiesDecisionsIntoBackup() async throws {
        let sandbox = try Sandbox()
        try sandbox.writeDecision(named: "26.03.22.fen_init_lab.json", contents: #"{"ZSC_1":"approved"}"#)

        try await sandbox.repository.createBackup(id: "20260811T060602Z")

        #expect(try sandbox.backupContents(id: "20260811T060602Z") == ["26.03.22.fen_init_lab.json"])
        #expect(try sandbox.backupFile(id: "20260811T060602Z", named: "26.03.22.fen_init_lab.json")
            == #"{"ZSC_1":"approved"}"#)
    }

    @Test
    func skipsBackupWhenDecisionsDirectoryMissing() async throws {
        let sandbox = try Sandbox(createDecisions: false)

        try await sandbox.repository.createBackup(id: "20260811T060602Z")

        #expect(try await sandbox.repository.backups().isEmpty)
    }

    // Стартовый снимок и премиграционный попадают в одну секунду — второй
    // не должен ни падать, ни затирать первый.
    @Test
    func keepsFirstBackupWhenIdRepeats() async throws {
        let sandbox = try Sandbox()
        try sandbox.writeDecision(named: "a.json", contents: "first")

        try await sandbox.repository.createBackup(id: "same")
        try sandbox.writeDecision(named: "a.json", contents: "second")
        try await sandbox.repository.createBackup(id: "same")

        #expect(try sandbox.backupFile(id: "same", named: "a.json") == "first")
    }

    @Test
    func listsBackupsNewestFirst() async throws {
        let sandbox = try Sandbox()
        try sandbox.writeDecision(named: "a.json", contents: "x")

        for id in ["first", "second", "third"] {
            try await sandbox.repository.createBackup(id: id)
            // Даты создания берутся у файловой системы, а её разрешение грубее вызова.
            try await Task.sleep(for: .milliseconds(1100))
        }

        let backups = try await sandbox.repository.backups()

        #expect(backups.map(\.id) == ["third", "second", "first"])
    }

    @Test
    func deletesRequestedBackup() async throws {
        let sandbox = try Sandbox()
        try sandbox.writeDecision(named: "a.json", contents: "x")
        try await sandbox.repository.createBackup(id: "doomed")

        try await sandbox.repository.deleteBackup(id: "doomed")

        #expect(try await sandbox.repository.backups().isEmpty)
    }
}

// Подменяет Documents на временную папку: репозиторий строит пути сам,
// и других швов для изоляции у него нет.
private final class SandboxFileManager: FileManager {
    private let root: URL

    init(root: URL) {
        self.root = root
        super.init()
    }

    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        [root]
    }
}

private struct Sandbox {
    let repository: FileDecisionsBackupRepository

    private let root: URL
    private let fileManager = FileManager.default

    init(createDecisions: Bool = true) throws {
        let root = URL.temporaryDirectory.appending(component: UUID().uuidString)
        let decisions = root.appending(component: "Cullen").appending(component: "decisions")

        try FileManager.default.createDirectory(
            at: createDecisions ? decisions : root,
            withIntermediateDirectories: true
        )

        self.root = root
        repository = FileDecisionsBackupRepository(fileManager: SandboxFileManager(root: root))
    }

    func writeDecision(named name: String, contents: String) throws {
        try Data(contents.utf8).write(to: decisionsDirectory.appending(component: name))
    }

    func backupContents(id: String) throws -> [String] {
        try fileManager
            .contentsOfDirectory(atPath: backupsDirectory.appending(component: id).path())
            .sorted()
    }

    func backupFile(id: String, named name: String) throws -> String {
        let url = backupsDirectory.appending(component: id).appending(component: name)

        return String(decoding: try Data(contentsOf: url), as: UTF8.self)
    }

    private var decisionsDirectory: URL {
        root.appending(component: "Cullen").appending(component: "decisions")
    }

    private var backupsDirectory: URL {
        root.appending(component: "Cullen").appending(component: "backups")
    }
}
