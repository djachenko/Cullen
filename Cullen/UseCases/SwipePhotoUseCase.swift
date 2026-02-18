//
//  SwipePhotoUseCase.swift
//  Cullen
//
//  Domain Layer - Business Logic for Photo Swiping
//

import Foundation

// MARK: - Swipe Photo Use Case
//
//protocol SwipePhotoUseCaseProtocol {
//    func execute(photoId: UUID, decision: Decision) async throws
//}

//final class SwipePhotoUseCase: SwipePhotoUseCaseProtocol {
//    
//    private let repository: PhotoRepository
//    private let syncService: SyncServiceProtocol
//    
//    init(repository: PhotoRepository, syncService: SyncServiceProtocol) {
//        self.repository = repository
//        self.syncService = syncService
//    }
//    
//    func execute(photoId: UUID, decision: Decision) async throws {
//        // Business Logic:
//        // 1. Update decision locally (offline-first)
//        try await repository.updatePhotoDecision(photoId, decision: decision)
//        
//        // 2. Mark as pending sync
//        try await repository.updateSyncStatus(photoId, status: .pending)
//        
//        // 3. Enqueue for background synchronization
//        await syncService.enqueueSyncTask(photoId: photoId)
//    }
//}
