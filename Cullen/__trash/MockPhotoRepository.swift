//
//  MockPhotoRepository.swift
//  Cullen
//
//  Data Layer - Mock Implementation
//

import Foundation


final class MockPhotoRepository: PhotoRepository {
    

    
    func fetchPhotos(for photosetId: PhotosetId) async throws -> [Photo] {
        // TODO: Implement when needed for photo detail view
        try await Task.sleep(nanoseconds: 300_000_000)
        return []
    }
    
    func updatePhotoDecision(_ photoId: PhotosetId, decision: Decision) async throws {
        // TODO: Implement when needed
        try await Task.sleep(nanoseconds: 100_000_000)
    }
    
    func getPendingSync() async throws -> [Photo] {
        // TODO: Implement when needed
        return []
    }
    
    func updateSyncStatus(_ photoId: PhotosetId, status: SyncStatus) async throws {
        // TODO: Implement when needed
        try await Task.sleep(nanoseconds: 100_000_000)
    }
}
