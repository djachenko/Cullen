//
//  DecisionsCodableFormatFalloutMigrationTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


struct DecisionsCodableFormatFalloutMigrationTests {
    static let photosetName = "26.03.22.fen_init_lab"

    // Формат-фоллаут: Codable-обёртка когда-то записала enum как {"approved":{}}.
    @Test
    func unwrapsCorruptedCodableFormat() async throws {
        let sandbox = try Sandbox()
        try sandbox.write(#"{"ZSC_1":{"approved":{}},"ZSC_2":{"rejected":{}}}"#)

        try await sandbox.migration.run()

        #expect(try sandbox.read() == ["ZSC_1": .approved, "ZSC_2": .rejected])
    }

    @Test
    func leavesHealthyFileUntouched() async throws {
        let sandbox = try Sandbox()
        let healthy = #"{"ZSC_1":"approved"}"#
        try sandbox.write(healthy)

        try await sandbox.migration.run()

        #expect(sandbox.raw() == healthy)
    }

    @Test
    func skipsMissingFile() async throws {
        let sandbox = try Sandbox()

        try await sandbox.migration.run()

        #expect(sandbox.raw() == nil)
    }
}

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
    let migration: DecisionsCodableFormatFalloutMigration

    private let file: URL

    init() throws {
        let root = URL.temporaryDirectory.appending(component: UUID().uuidString)
        let decisions = root.appending(component: "Cullen").appending(component: "decisions")

        try FileManager.default.createDirectory(at: decisions, withIntermediateDirectories: true)

        file = decisions.appending(component: "\(DecisionsCodableFormatFalloutMigrationTests.photosetName).json")
        migration = DecisionsCodableFormatFalloutMigration(
            photosetsRepository: FakePhotosetsRepository(
                photosets: [.stub(id: DecisionsCodableFormatFalloutMigrationTests.photosetName, photos: [])]
            ),
            fileManager: SandboxFileManager(root: root)
        )
    }

    func write(_ contents: String) throws {
        try Data(contents.utf8).write(to: file)
    }

    func read() throws -> [PhotoId: Decision] {
        try JSONDecoder().decode([PhotoId: Decision].self, from: Data(contentsOf: file))
    }

    func raw() -> String? {
        try? String(decoding: Data(contentsOf: file), as: UTF8.self)
    }
}
