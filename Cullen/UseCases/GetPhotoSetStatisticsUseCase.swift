//
//  GetPhotosetStatisticsUseCase.swift
//  Cullen
//
//  Domain Layer - Business Logic for Statistics
//

import Foundation

// MARK: - Get Statistics Use Case

protocol GetPhotosetStatisticsUseCase {
    func execute() async throws -> PhotosetStatistics
}

final class GetPhotosetStatisticsUseCaseImpl: GetPhotosetStatisticsUseCase {
    
    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> PhotosetStatistics {
        let photosets = try await repository.getPhotosets()

        // Business Logic: Calculate statistics
        let totalSets = photosets.count
        let totalPhotos = photosets
            .map { $0.photosCount }
            .reduce(0, +)
        let pendingSyncCount = photosets.count { $0.syncStatus == .pending }

        return PhotosetStatistics(
            totalSets: totalSets,
            totalPhotos: totalPhotos,
            pendingSyncCount: pendingSyncCount
        )
    }
}
