//
//  JsonPhotosRepository.swift
//  Cullen
//
//  Created by justin on 8/3/26.
//

import Foundation


actor JsonPhotosRepository {
    private var photosetCache: [PhotosetId: Task<Photoset, Error>] = [:]

    private lazy var indexTask = Task<[PhotosetId], Error> {
        try [String]
            .fromJson(name: "index")
            .map { $0.removing(suffix: ".json") }
            .map { .string($0) }
    }
}

extension JsonPhotosRepository: PhotosetsRepository {
    func getPhotosetIds() async throws -> [PhotosetId] {
        try await indexTask.value
    }

    func getPhotoset(id: PhotosetId) async throws -> Photoset {
        guard case .string(let filename) = id else {
            throw PhotosetsRepositoryError.notFound(id: id)
        }

        let task = photosetCache[id] ?? Task {
            Photoset(
                filename: filename,
                photos: try [PhotoEntry]
                    .fromJson(name: filename)
                    .map { Photo(entry: $0) }
            )
        }

        photosetCache[id] = task

        return try await task.value
    }

    func getPhotosets() async throws -> [Photoset] {
        let ids = try await getPhotosetIds()

        return try await withThrowingTaskGroup(of: (Int, Photoset?).self, returning: [Photoset].self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask { [weak self] in
                    (index, try await self?.getPhotoset(id: id))
                }
            }

            var results = [(Int, Photoset?)]()

            for try await (index, photoset) in group {
                results.append((index, photoset))
            }

            return results
                .sorted { $0.0 }
                .compactMap { $0.1 }
        }
    }
}


private struct PhotoEntry {
    let name: String
    let url: URL
}

extension PhotoEntry: Decodable {}


private extension Photo {
    init(entry: PhotoEntry) {
        self.init(
            id: entry.name,
            url: entry.url
        )
    }
}


private extension Photoset {
    init(filename: String, photos: [Photo]) {
        self.init(
            id: .string(filename),
            name: filename,
            remotePath: "/photosets/\(filename)",
            source: .vk,
            syncStatus: .synced,
            lastSyncDate: nil,
            createdAt: Photoset.date(filename: filename) ?? Date(),
            coverImageURL: photos.first?.url,
            photosCount: photos.count,
            approvedCount: 0,
            rejectedCount: 0,
            photos: photos
        )
    }

    private static func date(filename: String) -> Date? {
        let components = filename.split(separator: ".")

        guard components.count >= 3 else {
            return nil
        }

        let dateString = "\(components[0]).\(components[1]).\(components[2])"
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"

        return formatter.date(from: dateString)
    }
}
