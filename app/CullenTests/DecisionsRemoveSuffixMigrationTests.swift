//
//  DecisionsRemoveSuffixMigrationTests.swift
//  CullenTests
//

import Foundation
import Testing
@testable import Cullen


private enum Fixture {
    static let suffix: String = ".jpg"

    static let photosetName: String = "26.01.01.photoset_a"
    static let otherPhotosetName: String = "26.01.02.photoset_b"

    static let photosetId: PhotosetId = .string(photosetName)
    static let otherPhotosetId: PhotosetId = .string(otherPhotosetName)

    static let firstPhoto: PhotoId = "IMG_0001"
    static let secondPhoto: PhotoId = "IMG_0002"
    static let thirdPhoto: PhotoId = "IMG_0003"
}

private extension Dictionary where Key == PhotoId, Value == Decision {
    // Состояние «до миграции» строится из ожидаемого, а не выписывается второй раз руками:
    // разъехаться на опечатке в одной из двух копий уже нельзя.
    func withSuffixes() -> Self {
        Dictionary(uniqueKeysWithValues: map { ($0.key + Fixture.suffix, $0.value) })
    }
}

struct DecisionsRemoveSuffixMigrationTests {
    // Главный тест этой миграции: решения обязаны пережить переименование ключей.
    @Test
    func stripsSuffixKeepingEveryDecision() async throws {
        let expected: [PhotoId: Decision] = [
            Fixture.firstPhoto: .approved,
            Fixture.secondPhoto: .rejected,
            Fixture.thirdPhoto: .pending,
        ]
        let repository = MockDecisionsRepository(stored: [Fixture.photosetId: expected.withSuffixes()])

        try await migration(decisions: repository).run()

        #expect(try await repository.load(for: Fixture.photosetId) == expected)
    }

    @Test
    func skipsPhotosetWithoutDecisions() async throws {
        let repository = MockDecisionsRepository(stored: [Fixture.photosetId: [:]])

        try await migration(decisions: repository).run()

        #expect(repository.saves.isEmpty)
    }

    @Test
    func skipsAlreadyMigratedKeys() async throws {
        let repository = MockDecisionsRepository(stored: [Fixture.photosetId: [Fixture.firstPhoto: .approved]])

        try await migration(decisions: repository).run()

        #expect(repository.saves.isEmpty)
    }

    @Test
    func migratesEveryPhotosetInIndex() async throws {
        let expected: [PhotoId: Decision] = [Fixture.firstPhoto: .approved]
        let otherExpected: [PhotoId: Decision] = [Fixture.secondPhoto: .rejected]
        let repository = MockDecisionsRepository(stored: [
            Fixture.photosetId: expected.withSuffixes(),
            Fixture.otherPhotosetId: otherExpected.withSuffixes(),
        ])
        let photosets = MockPhotosetsRepository(photosets: [
            .stub(id: Fixture.photosetName, photos: []),
            .stub(id: Fixture.otherPhotosetName, photos: []),
        ])

        try await DecisionsRemoveSuffixMigration(
            decisionsRepository: repository,
            photosetsRepository: photosets
        ).run()

        #expect(try await repository.load(for: Fixture.photosetId) == expected)
        #expect(try await repository.load(for: Fixture.otherPhotosetId) == otherExpected)
    }
}

private extension DecisionsRemoveSuffixMigrationTests {
    func migration(decisions: MockDecisionsRepository) -> DecisionsRemoveSuffixMigration {
        DecisionsRemoveSuffixMigration(
            decisionsRepository: decisions,
            photosetsRepository: MockPhotosetsRepository(
                photosets: [.stub(id: Fixture.photosetName, photos: [])]
            )
        )
    }
}
