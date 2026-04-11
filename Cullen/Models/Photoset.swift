//
//  Photoset.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation

enum PhotosetId {
    case int(Int)
    case string(String)
    case uuid(UUID)

    static let mock: PhotosetId = .uuid(UUID())
}

extension PhotosetId: Hashable {}


struct Photoset: Identifiable, Hashable {
    let id: PhotosetId
    let name: String
    let remotePath: String
    var syncStatus: SyncStatus
    var lastSyncDate: Date?
    let createdAt: Date
    let coverImageURL: URL?
    let photosCount: Int
    let approvedCount: Int
    let rejectedCount: Int
    let photos: [URL]

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
