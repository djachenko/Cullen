//
//  Photoset.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation


struct Photoset: Identifiable, Hashable {
    let id: UUID
    let name: String
    let remotePath: String
    var syncStatus: SyncStatus
    var lastSyncDate: Date?
    let createdAt: Date
    let coverImageURL: URL?
    let photosCount: Int
    let approvedCount: Int
    let rejectedCount: Int
    
    var pendingCount: Int {
        photosCount - approvedCount - rejectedCount
    }
    
    var progressPercentage: Double {
        guard photosCount > 0 else { return 0 }
        return Double(approvedCount + rejectedCount) / Double(photosCount)
    }
    
    var isCompleted: Bool {
        pendingCount == 0
    }
}
