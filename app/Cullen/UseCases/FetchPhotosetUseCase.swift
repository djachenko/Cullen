//
//  FetchPhotosetUseCase.swift
//  Cullen
//
//  Created by justin on 21/3/26.
//

import Foundation


protocol FetchPhotosetUseCase {
    func execute(id: PhotosetId) async throws -> Photoset
}

final class FetchPhotosetUseCaseImpl: FetchPhotosetUseCase {
    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }

    func execute(id: PhotosetId) async throws -> Photoset {
        try await repository.getPhotoset(id: id)
    }
}
