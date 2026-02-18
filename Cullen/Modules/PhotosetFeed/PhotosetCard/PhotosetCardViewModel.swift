//
//  PhotosetCardViewModel.swift
//  Cullen
//
//  Created by justin on 14/2/26.
//

import Foundation


struct PhotosetCardViewModel: Identifiable, Hashable {
    let id: UUID
    let name: String
    let photosCountText: String
    let progressPercentage: Double
    let approvedCount: Int
    let rejectedCount: Int
    let pendingCount: Int
    let syncBadge: SyncBadgeViewModel
    let coverImageURL: URL?
}

extension PhotosetCardViewModel {
    init(from entity: Photoset) {
        self.init(
            id: entity.id,
            name: entity.name,
            photosCountText: "\(entity.photosCount) photos",
            progressPercentage: entity.progressPercentage,
            approvedCount: entity.approvedCount,
            rejectedCount: entity.rejectedCount,
            pendingCount: entity.pendingCount,
            syncBadge: SyncBadgeViewModel(from: entity.syncStatus),
            coverImageURL: entity.coverImageURL,
        )
    }
}
