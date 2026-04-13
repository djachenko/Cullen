//
//  RepositoryProtocols.swift
//  Cullen
//
//  Domain Layer - Repository Interfaces
//

import Foundation

// MARK: - Photo Repository Protocol

protocol PhotoRepository {
//    /// Fetch photos for a specific photo set
//    func fetchPhotos(for photosetId: PhotosetId) async throws -> [Photo]
//    
//    /// Update photo decision (approve/reject)
//    func updatePhotoDecision(_ photoId: PhotosetId, decision: Decision) async throws
//    
//    /// Get all photos that need synchronization
//    func getPendingSync() async throws -> [Photo]
//    
//    /// Update sync status after synchronization
//    func updateSyncStatus(_ photoId: PhotosetId, status: SyncStatus) async throws
}

// MARK: - Sync Service Protocol

protocol SyncServiceProtocol {
//    /// Enqueue a photo for synchronization
//    func enqueueSyncTask(photoId: PhotosetId) async
//    
//    /// Start periodic background synchronization
//    func startPeriodicSync() async
//    
//    /// Force immediate synchronization
//    func syncNow() async throws
//    
//    /// Get current sync queue size
//    func getPendingSyncCount() async -> Int
}

// MARK: - Image Cache Protocol

protocol ImageCacheProtocol {
//    /// Prefetch images for a photo set
//    func prefetchImages(urls: [URL]) async
//    
//    /// Clear cache for specific photo set
//    func clearCache(for photosetId: PhotosetId) async
//    
//    /// Get cache size
//    func getCacheSize() async -> Int64
}
