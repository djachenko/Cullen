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

    @available(*, deprecated, renamed: "getPhotosetIds()")
    func getPhotosets() async throws -> [Photoset]
}

enum PhotosetsRepositoryError: Error {
    case notFound(id: PhotosetId)
}
