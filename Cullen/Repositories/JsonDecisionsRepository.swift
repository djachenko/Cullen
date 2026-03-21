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

    enum Error: Swift.Error {
        case directoryUnavailable
    }

    private let directory: URL?

    init(fileManager: FileManager) {
        let documents = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first

        let directory = documents?
            .appending(component: Constants.directoryName)
            .appending(component: Constants.subdirectory)

        if let directory {
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )

                self.directory = directory
            } catch {
                self.directory = nil
            }
        } else {
            self.directory = nil
        }
    }

    private func fileURL(for photosetId: PhotosetId) throws -> URL {
        guard let directory else {
            throw Error.directoryUnavailable
        }

        return directory.appending(component: "\(photosetId.stringValue).json")
    }
}

extension JsonDecisionsRepository: DecisionsRepository {
    func load(for photosetId: PhotosetId) async throws -> [PhotoId: Decision] {
        let url = try fileURL(for: photosetId)

        guard FileManager.default.fileExists(atPath: url.path()) else {
            return [:]
        }

        let data = try Data(contentsOf: url)

        return try JSONDecoder().decode([PhotoId: Decision].self, from: data)
    }

    func save(decisions: [PhotoId: Decision], for photosetId: PhotosetId) async throws {
        let url = try fileURL(for: photosetId)
        let data = try JSONEncoder().encode(decisions)
        try data.write(to: url, options: .atomic)
    }
}
