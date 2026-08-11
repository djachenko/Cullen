//
//  DecisionsRemoveSuffixMigrationTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


struct DecisionsRemoveSuffixMigrationTests {
    private let photosetId = PhotosetId.string("26.03.22.fen_init_lab")

    // Главный тест этой миграции: решения обязаны пережить переименование ключей.
    @Test
    func stripsSuffixKeepingEveryDecision() async throws {
        let decisions: [PhotoId: Decision] = [
            "ZSC_1690.jpg": .approved,
            "ZSC_1691.jpg": .rejected,
            "ZSC_1692.jpg": .pending,
        ]
        let repository = FakeDecisionsRepository(stored: [photosetId: decisions])

        try await migration(decisions: repository).run()

        #expect(try await repository.load(for: photosetId) == [
            "ZSC_1690": .approved,
            "ZSC_1691": .rejected,
            "ZSC_1692": .pending,
        ])
    }

    @Test
    func skipsPhotosetWithoutDecisions() async throws {
        let repository = FakeDecisionsRepository(stored: [photosetId: [:]])

        try await migration(decisions: repository).run()

        #expect(repository.saves.isEmpty)
    }

    @Test
    func skipsAlreadyMigratedKeys() async throws {
        let repository = FakeDecisionsRepository(stored: [photosetId: ["ZSC_1690": .approved]])

        try await migration(decisions: repository).run()

        #expect(repository.saves.isEmpty)
    }

    @Test
    func migratesEveryPhotosetInIndex() async throws {
        let other = PhotosetId.string("26.05.01.maevka")
        let repository = FakeDecisionsRepository(stored: [
            photosetId: ["ZSC_1.jpg": .approved],
            other: ["ZSC_2.jpg": .rejected],
        ])
        let photosets = FakePhotosetsRepository(photosets: [
            .stub(id: "26.03.22.fen_init_lab", photos: []),
            .stub(id: "26.05.01.maevka", photos: []),
        ])

        try await DecisionsRemoveSuffixMigration(
            decisionsRepository: repository,
            photosetsRepository: photosets
        ).run()

        #expect(try await repository.load(for: photosetId) == ["ZSC_1": .approved])
        #expect(try await repository.load(for: other) == ["ZSC_2": .rejected])
    }
}

private extension DecisionsRemoveSuffixMigrationTests {
    func migration(decisions: FakeDecisionsRepository) -> DecisionsRemoveSuffixMigration {
        DecisionsRemoveSuffixMigration(
            decisionsRepository: decisions,
            photosetsRepository: FakePhotosetsRepository(
                photosets: [.stub(id: "26.03.22.fen_init_lab", photos: [])]
            )
        )
    }
}
