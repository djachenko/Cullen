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
        let photosets = try await repository.getPhotosets()

        guard let photoset = photosets.first(where: { $0.id == id }) else {
            throw Error.photosetNotFound(id: id)
        }

        // TODO: load actual decisions from persistence
        return photoset.photos.map {
            Photo(
                id: $0.lastPathComponent,
                url: $0
            )
        }
    }
}
