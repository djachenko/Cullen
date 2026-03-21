//
//  DecisionsUseCase.swift
//  Cullen
//
//  Created by justin on 18/3/26.
//

import Foundation


protocol SaveDecisionUseCase {
    func execute(photoId: PhotoId, decision: Decision, in photosetId: PhotosetId) async throws
}

protocol LoadDecisionsUseCase {
    func execute(for photosetId: PhotosetId) async throws -> [PhotoId: Decision]
}

actor DecisionsUseCaseImpl {
    private let repository: DecisionsRepository
    private var cache: [PhotosetId: [PhotoId: Decision]] = [:]

    init(repository: DecisionsRepository) {
        self.repository = repository
    }
}

extension DecisionsUseCaseImpl: SaveDecisionUseCase {
    func execute(photoId: PhotoId, decision: Decision, in photosetId: PhotosetId) async throws {
        if cache[photosetId] == nil {
            cache[photosetId] = (try? await repository.load(for: photosetId)) ?? [:]
        }
        cache[photosetId]?[photoId] = decision

        try await repository.save(decisions: cache[photosetId] ?? [:], for: photosetId)
    }
}

extension DecisionsUseCaseImpl: LoadDecisionsUseCase {
    func execute(for photosetId: PhotosetId) async throws -> [PhotoId: Decision] {
        if let cached = cache[photosetId] {
            return cached
        }
        let loaded = try await repository.load(for: photosetId)
        cache[photosetId] = loaded
        return loaded
    }
}
