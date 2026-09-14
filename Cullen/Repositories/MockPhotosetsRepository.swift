//
//  MockPhotosetsRepository.swift
//  Cullen
//
//  Created by justin on 25/3/26.
//


final class MockPhotosetsRepository {}

extension MockPhotosetsRepository: PhotosetsRepository {
    func getPhotosetIds() async throws -> [PhotosetId] { [] }
    func getPhotoset(id: PhotosetId) async throws -> Photoset { throw PhotosetsRepositoryError.notFound(id: id) }

    func getPhotosets() async throws -> [Photoset] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
}
