//
//  MockServices.swift
//  Cullen
//
//  Data Layer - Mock Service Implementations
//

import Foundation

// MARK: - Mock Sync Service

final class MockSyncService: SyncServiceProtocol {
    
    private var pendingQueue: [PhotosetId] = []
    
    func enqueueSyncTask(photoId: PhotosetId) async {
        pendingQueue.append(photoId)
        print("📤 Enqueued photo \(photoId) for sync")
    }
    
    func startPeriodicSync() async {
        print("🔄 Starting periodic sync...")
    }
    
    func syncNow() async throws {
        print("⚡ Force sync now...")
        try await Task.sleep(nanoseconds: 1_000_000_000)
        pendingQueue.removeAll()
    }
    
    func getPendingSyncCount() async -> Int {
        return pendingQueue.count
    }
}

// MARK: - Mock Image Cache

final class MockImageCache: ImageCacheProtocol {
    
    private var cachedPhotosets: Set<PhotosetId> = []
    
    func prefetchImages(urls: [URL]) async {
        print("🖼️ Prefetching \(urls.count) images...")
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func clearCache(for photosetId: PhotosetId) async {
        cachedPhotosets.remove(photosetId)
        print("🗑️ Cleared cache for photo set \(photosetId)")
    }
    
    func getCacheSize() async -> Int64 {
        return Int64(cachedPhotosets.count * 5_000_000) // 5MB per set
    }
}
