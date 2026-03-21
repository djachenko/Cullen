//
//  FetchPhotosetsUseCase.swift
//  Cullen
//
//  Created by justin on 21/3/26.
//

import Foundation


protocol FetchPhotosetsUseCase {
    func execute() async throws -> [PhotosetId]
}

final class FetchPhotosetsUseCaseImpl: FetchPhotosetsUseCase {
    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }

    func execute() async throws -> [PhotosetId] {
        try await repository.getPhotosetIds()
    }
}
