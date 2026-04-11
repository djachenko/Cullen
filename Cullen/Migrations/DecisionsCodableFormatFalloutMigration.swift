//
//  DecisionsCodableFormatFalloutMigration.swift
//  Cullen
//
//  Created by justin on 28/3/26.
//

import Foundation


final class DecisionsCodableFormatFalloutMigration: Migration {
    private enum Constants {
        static let directoryName = "Cullen"
        static let subdirectory  = "decisions"
    }

    let key: String? = nil

    private let photosetsRepository: PhotosetsRepository

    private let fileManager = FileManager.default

    private lazy var directory = fileManager
        .urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first?
        .appending(component: Constants.directoryName)
        .appending(component: Constants.subdirectory)

    init(
        photosetsRepository: PhotosetsRepository
    ) {
        self.photosetsRepository = photosetsRepository
    }

    func run() async throws {
        guard let directory else {
            return
        }

        let photosetIds = try await photosetsRepository.getPhotosetIds()

        for photosetId in photosetIds {
            let photosetDecisionsURL = directory.appending(component: "\(photosetId).json")

            guard fileManager.fileExists(atPath: photosetDecisionsURL.path()),
                  let corrupted = try? [PhotoId: [String: [String: String]]].fromJson(at: photosetDecisionsURL) else {
                continue
            }

            let migrated = corrupted.compactMapValues { dict in
                guard dict.count == 1 else {
                    fatalError("Corrupted corrupted: \(dict)???")
                }

                return Decision(rawValue: dict.keys.first!)
            }

            try migrated.toJson(at: photosetDecisionsURL)
        }
    }
}
