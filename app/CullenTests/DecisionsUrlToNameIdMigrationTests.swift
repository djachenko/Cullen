//
//  DecisionsUrlToNameIdMigrationTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


struct DecisionsUrlToNameIdMigrationTests {
    private let photosetId = PhotosetId.string("26.03.22.fen_init_lab")

    // Историческая форма ключа — последний компонент URL; переносим на photo.id.
    @Test
    func rekeysDecisionsFromUrlToPhotoId() async throws {
        let photo = Photo.stub(id: "ZSC_1690", url: "https://cdn.example.com/AUfDd0.jpg")
        let repository = FakeDecisionsRepository(stored: [photosetId: ["AUfDd0.jpg": .approved]])

        try await migration(decisions: repository, photos: [photo]).run()

        #expect(try await repository.load(for: photosetId) == ["ZSC_1690": .approved])
    }

    @Test
    func keepsDecisionsWithoutMatchingPhoto() async throws {
        let photo = Photo.stub(id: "ZSC_1690", url: "https://cdn.example.com/AUfDd0.jpg")
        let repository = FakeDecisionsRepository(stored: [photosetId: ["stranger.jpg": .rejected]])

        try await migration(decisions: repository, photos: [photo]).run()

        #expect(repository.saves.isEmpty)
        #expect(try await repository.load(for: photosetId) == ["stranger.jpg": .rejected])
    }

    @Test
    func rekeysOnlyMatchingEntries() async throws {
        let photo = Photo.stub(id: "ZSC_1690", url: "https://cdn.example.com/AUfDd0.jpg")
        let repository = FakeDecisionsRepository(stored: [photosetId: [
            "AUfDd0.jpg": .approved,
            "untouched": .rejected,
        ]])

        try await migration(decisions: repository, photos: [photo]).run()

        #expect(try await repository.load(for: photosetId) == [
            "ZSC_1690": .approved,
            "untouched": .rejected,
        ])
    }

    @Test
    func skipsPhotosetWithoutDecisions() async throws {
        let repository = FakeDecisionsRepository(stored: [photosetId: [:]])

        try await migration(decisions: repository, photos: []).run()

        #expect(repository.saves.isEmpty)
    }

    // Повторный прогон не должен приводить к записи: миграция объявлена
    // как always-run, и лишний save на каждом старте — это IO на ровном месте.
    @Test
    func isIdempotent() async throws {
        let photo = Photo.stub(id: "ZSC_1690", url: "https://cdn.example.com/AUfDd0.jpg")
        let repository = FakeDecisionsRepository(stored: [photosetId: ["AUfDd0.jpg": .approved]])

        try await migration(decisions: repository, photos: [photo]).run()
        try await migration(decisions: repository, photos: [photo]).run()

        #expect(repository.saves.count == 1)
    }
}

private extension DecisionsUrlToNameIdMigrationTests {
    func migration(decisions: FakeDecisionsRepository, photos: [Photo]) -> DecisionsUrlToNameIdMigration {
        DecisionsUrlToNameIdMigration(
            decisionsRepository: decisions,
            photosetsRepository: FakePhotosetsRepository(
                photosets: [.stub(id: "26.03.22.fen_init_lab", photos: photos)]
            )
        )
    }
}
