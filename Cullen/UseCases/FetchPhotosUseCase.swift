//
//  FetchPhotosUseCase.swift
//  Cullen
//
//  Created by justin on 7/3/26.
//

import Foundation

protocol FetchPhotosUseCase {
    func execute(id: PhotosetId) async throws -> [Photo]?
}

final class FetchPhotosUseCaseImpl {
    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }
}

extension FetchPhotosUseCaseImpl: FetchPhotosUseCase {
    func execute(id: PhotosetId) async throws -> [Photo]? {
        try await repository.getPhotosets()
            .first { $0.id == id }?
            .photos
            .map {
                Photo(
                    id: $0.lastPathComponent,
                    url: $0,
                    decision: .mock
                )
            }
    }
}
