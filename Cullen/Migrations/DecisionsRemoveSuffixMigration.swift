//
//  DecisionsRemoveSuffixMigration.swift
//  Cullen
//
//  Created by justin on 28/3/26.
//

import Foundation


final class DecisionsRemoveSuffixMigration: Migration {
    let key: String? = "decisions_remove_prefix_migration"

    private let decisionsRepository: DecisionsRepository
    private let photosetsRepository: PhotosetsRepository

    init(
        decisionsRepository: DecisionsRepository,
        photosetsRepository: PhotosetsRepository
    ) {
        self.decisionsRepository = decisionsRepository
        self.photosetsRepository = photosetsRepository
    }

    func run() async throws {
        let photosetIds = try await photosetsRepository.getPhotosetIds()

        for photosetId in photosetIds {
            let decisions = try await decisionsRepository.load(for: photosetId)

            guard !decisions.isEmpty else {
                continue
            }

            let migrated = decisions.reduce(into: [:]) { acc, e in
                acc[e.key.removing(suffix: ".jpg")] = e.value
            }

            guard migrated != decisions else {
                continue
            }

            try await decisionsRepository.save(decisions: migrated, for: photosetId)
        }
    }
}
