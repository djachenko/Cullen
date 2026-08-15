//
//  PhotoCountSortStrategy.swift
//  Cullen
//

final class PhotoCountSortStrategy: PhotosetSortStrategy {
    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }

    func sorted(ids: [PhotosetId], isAscending: Bool) async throws -> [PhotosetId] {
        let photosets = try await repository.photosets(ids: ids)

        return ids.sorted(by: { photosets[$0]?.photosCount ?? .zero }, reverse: !isAscending)
    }
}
