//
//  JsonDecisionsRepository.swift
//  Cullen
//
//  Created by justin on 18/3/26.
//

import Foundation


final class JsonDecisionsRepository {
    private enum Constants {
        static let directoryName = "Cullen"
        static let subdirectory  = "decisions"
    }

    private let directory: URL
    private let fileManager: FileManager

    init(fileManager: FileManager) {
        self.fileManager = fileManager
        self.directory = fileManager
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first!
                .appending(component: Constants.directoryName)
                .appending(component: Constants.subdirectory)

        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }
}

extension JsonDecisionsRepository: DecisionsRepository {
    func load(for photosetId: PhotosetId) async throws -> [PhotoId: Decision] {
        let url = try fileURL(for: photosetId)

        guard fileManager.fileExists(atPath: url.path()) else {
            return [:]
        }

        return try [PhotoId: Decision].fromJson(at: url)
    }

    func save(decisions: [PhotoId: Decision], for photosetId: PhotosetId) async throws {
        let url = try fileURL(for: photosetId)
        try decisions.toJson(at: url)
    }
}

private extension JsonDecisionsRepository {
    func fileURL(for photosetId: PhotosetId) throws -> URL {
        directory.appending(component: "\(photosetId).json")
    }
}
