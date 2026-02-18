//
//  GetPhotosetStatisticsUseCase.swift
//  Cullen
//
//  Domain Layer - Business Logic for Statistics
//

import Foundation

// MARK: - Get Statistics Use Case

protocol GetPhotosetStatisticsUseCaseProtocol {
    func execute() async throws -> PhotosetStatistics
}

final class GetPhotosetStatisticsUseCase: GetPhotosetStatisticsUseCaseProtocol {
    
    private let repository: PhotosetsRepository

    init(repository: PhotosetsRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> PhotosetStatistics {
        let photoSets = try await repository.getPhotosets()

        // Business Logic: Calculate statistics
        let totalSets = photoSets.count
        let totalPhotos = photoSets
            .map { $0.photosCount }
            .reduce(0, +)
        let completedSets = photoSets.count { $0.isCompleted }
        let pendingSyncCount = photoSets.count { $0.syncStatus == .pending }

        return PhotosetStatistics(
            totalSets: totalSets,
            totalPhotos: totalPhotos,
            completedSets: completedSets,
            pendingSyncCount: pendingSyncCount
        )
    }
}
