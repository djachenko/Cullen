//
//  ExportDecisionsUseCase.swift
//  Cullen
//
//  Created by justin on 21/3/26.
//

import Foundation


protocol ExportDecisionsUseCase {
    func execute(photosetId: PhotosetId, source: PhotosetSource) async throws -> Data
}

final class ExportDecisionsUseCaseImpl {
    private let decisionsRepository: DecisionsRepository
    private let photosetsRepository: PhotosetsRepository

    init(
        decisionsRepository: DecisionsRepository,
        photosetsRepository: PhotosetsRepository
    ) {
        self.decisionsRepository = decisionsRepository
        self.photosetsRepository = photosetsRepository
    }
}

extension ExportDecisionsUseCaseImpl: ExportDecisionsUseCase {
    func execute(photosetId: PhotosetId, source: PhotosetSource) async throws -> Data {
        let decisions = try await decisionsRepository.load(for: photosetId)
        let actualDecisions = decisions.filter { $0.value != .pending }

        let decisionsPayload: [String: [Int]]

        switch source {
        case .vk:
            let photoset = try await photosetsRepository.getPhotoset(id: photosetId)

            var grouped: [String: [Int]] = [:]

            photoset.photos
                .enumerated()
                .forEach { index, url in
                    guard let decision = actualDecisions[url.lastPathComponent] else {
                        return
                    }

                    grouped[decision.exportKey, default: []].append(index)
                }

            decisionsPayload = grouped
        }

        let export: [String: Any] = [
            "key_strategy": source.keyStrategy,
            "decisions": decisionsPayload,
        ]

        return try JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
    }
}

private extension Decision {
    var exportKey: String {
        switch self {
        case .approved:
            "good"
        case .rejected:
            "bad"
        case .pending:
            "pending"
        }
    }
}
