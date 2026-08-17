//
//  FakePhotosetsRepository.swift
//  CullenTests
//

import Foundation
@testable import Cullen


final class FakePhotosetsRepository: PhotosetsRepository {
    private let photosets: [PhotosetId: Photoset]

    init(photosets: [Photoset]) {
        self.photosets = Dictionary(uniqueKeysWithValues: photosets.map { ($0.id, $0) })
    }

    func getPhotosetIds() async throws -> [PhotosetId] {
        photosets.keys.sorted { "\($0)" < "\($1)" }
    }

    func getPhotoset(id: PhotosetId) async throws -> Photoset {
        guard let photoset = photosets[id] else {
            throw PhotosetsRepositoryError.notFound(id: id)
        }

        return photoset
    }

    func getPhotosets() async throws -> [Photoset] {
        Array(photosets.values)
    }
}

extension Photoset {
    // Миграции смотрят только на id и photos — остальное шум, который в тестах
    // незачем перечислять на каждом вызове.
    static func stub(id: String, photos: [Photo]) -> Photoset {
        Photoset(
            id: .string(id),
            name: id,
            syncStatus: .synced,
            coverImageURL: nil,
            photosCount: photos.count,
            photos: photos,
            date: nil
        )
    }
}

extension Photo {
    static func stub(id: PhotoId, url: String = "https://example.com/photo.jpg") -> Photo {
        Photo(id: id, url: URL(string: url)!)
    }
}
