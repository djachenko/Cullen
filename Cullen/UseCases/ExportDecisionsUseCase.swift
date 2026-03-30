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
        let decisions = try await decisionsRepository
            .load(for: photosetId)
            .filter { $0.value != .pending }

        var decisionsPayload: [String: [PhotoId]] = [:]

        decisions.forEach { photoId, decision in
            decisionsPayload[decision.exportKey, default: []].append(photoId)
        }

        let export: [String: Any] = [
            "decisions": decisionsPayload,
            "name": String(describing: photosetId),
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
