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
    private let photosetsRepository: PhotosetsRepository

    private var cache: [PhotosetId: [PhotoId: Decision]] = [:]

    init(repository: DecisionsRepository, photosetsRepository: PhotosetsRepository) {
        self.repository = repository
        self.photosetsRepository = photosetsRepository
    }
}

extension DecisionsUseCaseImpl: SaveDecisionUseCase {
    func execute(photoId: PhotoId, decision: Decision, in photosetId: PhotosetId) async throws {
        var decisions = try await warmedUp(photosetId: photosetId)

        decisions[photoId] = decision
        cache[photosetId] = decisions

        try await repository.save(decisions: cache[photosetId] ?? [:], for: photosetId)
    }
}

extension DecisionsUseCaseImpl: LoadDecisionsUseCase {
    func execute(for photosetId: PhotosetId) async throws -> [PhotoId: Decision] {
        try await warmedUp(photosetId: photosetId)
    }
}

private extension DecisionsUseCaseImpl {
    func warmedUp(photosetId: PhotosetId) async throws -> [PhotoId: Decision] {
        if let cached = cache[photosetId] {
            return cached
        }

        let loaded = try await repository.load(for: photosetId)

        cache[photosetId] = loaded
        return loaded
    }
}
