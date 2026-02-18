//
//  FetchPhotosetsUseCase.swift
//  CullenApp
//
//  Domain Layer - Business Logic
//

import Foundation

// MARK: - Fetch Photo Sets Use Case

protocol FetchPhotosetsUseCaseProtocol {
    func execute(sortBy: PhotosetSortOption, searchQuery: String?) async throws -> [Photoset]
}

final class FetchPhotosetsUseCase: FetchPhotosetsUseCaseProtocol {
    
    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }
    
    func execute(
        sortBy: PhotosetSortOption = .recent,
        searchQuery: String? = nil
    ) async throws -> [Photoset] {
        // 1. Fetch from repository
        var photoSets = try await repository.getPhotosets()

        // 2. Business Logic: Filter by search query
        if let query = searchQuery,
            !query.isEmpty {
            photoSets = photoSets.filter { photoSet in
                photoSet.name.localizedCaseInsensitiveContains(query)
            }
        }
        
        // 3. Business Logic: Sort
        switch sortBy {
        case .recent:
            photoSets.sort { $0.createdAt > $1.createdAt }
        case .name:
            photoSets.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .progress:
            photoSets.sort { $0.progressPercentage > $1.progressPercentage }
        case .photoCount:
            photoSets.sort { $0.photosCount > $1.photosCount }
        }
        
        return photoSets
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
