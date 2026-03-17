//
//  PhotosetCardViewModel.swift
//  Cullen
//
//  Created by justin on 14/2/26.
//

import Foundation


struct PhotosetCardViewModel: Identifiable, Hashable {
    let id: PhotosetId
    let title: String
    let photosCountText: String
    let progressPercentage: Double // TODO: need to store?
    let approvedCount: Int
    let rejectedCount: Int
    let pendingCount: Int // TODO: need to store?
    let syncBadge: SyncBadgeViewModel
    let coverImageURL: URL?
}

extension PhotosetCardViewModel {
    init(from entity: PhotosetInfo) {
        let pendingCount = entity.photosCount - entity.approvedCount - entity.rejectedCount
        let progress = 1 - Double(pendingCount) / Double(entity.photosCount)

        self.init(
            id: entity.id,
            title: entity.title,
            photosCountText: String(entity.photosCount),
            progressPercentage: progress,
            approvedCount: entity.approvedCount,
            rejectedCount: entity.rejectedCount,
            pendingCount: pendingCount,
            syncBadge: SyncBadgeViewModel(from: .synced),
            coverImageURL: entity.coverUrl
        )
    }
}
