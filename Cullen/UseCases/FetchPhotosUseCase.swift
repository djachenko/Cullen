//
//  FetchPhotosUseCase.swift
//  Cullen
//
//  Created by justin on 7/3/26.
//

import Foundation


protocol FetchPhotosUseCase {
    func execute(id: PhotosetId) async throws -> [Photo]
}

final class FetchPhotosUseCaseImpl {
    enum Error: Swift.Error {
        case photosetNotFound(id: PhotosetId)
    }

    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }
}

extension FetchPhotosUseCaseImpl: FetchPhotosUseCase {
    func execute(id: PhotosetId) async throws -> [Photo] {
        try await repository
            .getPhotoset(id: id)
            .photos
    }
}
