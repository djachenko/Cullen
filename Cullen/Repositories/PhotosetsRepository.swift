//
//  PhotosetsRepository.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation


protocol PhotosetsRepository {
    func getPhotosetIds() async throws -> [PhotosetId]
    func getPhotoset(id: PhotosetId) async throws -> Photoset
    func getPhotosets() async throws -> [Photoset]
}

enum PhotosetsRepositoryError: Error {
    case notFound(id: PhotosetId)
}

struct PhotosetModel {
    let id: Int
    let name: String
    let created: Int
    let cover_index: Int?
    let photos: [String]

    var coverUrl: String? {
        cover_index.map { photos[$0] }
    }
}

final class MockPhotosetsRepository {}

extension MockPhotosetsRepository: PhotosetsRepository {
    func getPhotosetIds() async throws -> [PhotosetId] { [] }
    func getPhotoset(id: PhotosetId) async throws -> Photoset { throw PhotosetsRepositoryError.notFound(id: id) }
    func getPhotosets() async throws -> [Photoset] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
}
