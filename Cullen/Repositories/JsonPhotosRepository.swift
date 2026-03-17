//
//  JsonPhotosRepository.swift
//  Cullen
//
//  Created by justin on 8/3/26.
//

import Foundation

struct PhotosetDTO: Decodable {
    let id: Int
    let name: String
    let created: TimeInterval
    let coverIndex: Int?
    let photos: [URL]
    let approvedCount: Int
    let rejectedCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, created, photos
        
        case coverIndex = "cover_index"
        case approvedCount = "approved_count"
        case rejectedCount = "rejected_count"
    }
}

extension PhotosetDTO {
    func toDomain() -> Photoset {
        Photoset(
            id: .int(id),
            name: name,
            remotePath: "/photosets/\(id)",
            syncStatus: SyncStatus.allCases.randomElement() ?? .pending,
            lastSyncDate: Bool.random() ? Date() : nil,
            createdAt: Date(timeIntervalSince1970: created),
            coverImageURL: coverIndex.map { photos[$0] },
            photosCount: photos.count,
            approvedCount: approvedCount,
            rejectedCount: rejectedCount,
            photos: photos
        )
    }
}

final class JsonPhotosRepository {
    private lazy var task = Task {
        guard let url = Bundle.main.url(forResource: "cullen", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }

        let data = try Data(contentsOf: url)
        let dtos = try JSONDecoder().decode([PhotosetDTO].self, from: data)

        return dtos.map { $0.toDomain() }
    }
}

extension JsonPhotosRepository: PhotosetsRepository {
    func getPhotosets() async throws -> [Photoset] {
        try await task.value
    }
}
