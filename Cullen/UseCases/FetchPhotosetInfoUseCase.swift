//
//  FetchPhotosetInfoUseCase.swift
//  Cullen
//
//  Domain Layer - Business Logic
//

import Foundation


protocol FetchPhotosetInfoUseCase {
    func execute(sortBy: PhotosetSortOption, searchQuery: String?) async throws -> [PhotosetInfo]
}

final class FetchPhotosetsUseCaseImpl {

    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }
}

extension FetchPhotosetsUseCaseImpl: FetchPhotosetInfoUseCase {

    func execute(
        sortBy: PhotosetSortOption = .recent,
        searchQuery: String? = nil
    ) async throws -> [PhotosetInfo] {
        // 1. Fetch from repository
        var photosets = try await repository.getPhotosets()

        if let query = searchQuery,
            !query.isEmpty {
            photosets = photosets.filter { photoset in
                photoset.name.localizedCaseInsensitiveContains(query)
            }
        }
        
        switch sortBy {
        case .recent:
            photosets.sort { $0.createdAt > $1.createdAt }
        case .name:
            photosets.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .progress:
            photosets.sort { $0.progressPercentage > $1.progressPercentage }
        case .photoCount:
            photosets.sort { $0.photosCount > $1.photosCount }
        }
        
        return photosets.map { PhotosetInfo(photoset: $0) }
    }
}

extension PhotosetInfo {
    init(photoset: Photoset) {
        self.init(
            id: photoset.id,
            title: photoset.name,
            coverUrl: photoset.coverImageURL,
            photosCount: photoset.photosCount,
            approvedCount: photoset.approvedCount,
            rejectedCount: photoset.rejectedCount
        )
    }
}

// MARK: - Sort Options

enum PhotosetSortOption: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case name = "Name"
    case progress = "Progress"
    case photoCount = "Photos"
    
    var id: String { rawValue }

    static let `default` = Self.recent
}
