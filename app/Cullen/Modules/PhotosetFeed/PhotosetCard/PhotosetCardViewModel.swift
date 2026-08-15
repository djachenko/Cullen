//
//  PhotosetCardViewModel.swift
//  Cullen
//
//  Created by justin on 14/2/26.
//

import Foundation
import SwiftUI
import Combine


@MainActor
final class PhotosetCardViewModel: ObservableObject {

    enum State {
        case loading
        case content(Content)
        case error
    }

    struct Content {
        let title: String
        let coverUrl: URL?
        let photosCount: Int
        let approvedCount: Int
        let rejectedCount: Int
        let pendingCount: Int
        let progressPercentage: Double
        let syncBadge: SyncBadgeViewModel
    }

    @Published var state: State = .loading


    let id: PhotosetId

    var progress: Double {
        syncUseCase.progress ?? 0
    }

    var isSyncing: Bool {
        syncUseCase.isSyncing
    }

    private let syncUseCase: PhotosetSyncUseCase
    private let fetchPhotosetUseCase: FetchPhotosetUseCase
    private let decisionsStatsUseCase: DecisionsStatsUseCase
    private let coordinator: Coordinator

    init(
        id: PhotosetId,
        fetchPhotosetUseCase: FetchPhotosetUseCase,
        decisionsStatsUseCase: DecisionsStatsUseCase,
        syncUseCase: PhotosetSyncUseCase,
        coordinator: Coordinator
    ) {
        self.id = id
        self.fetchPhotosetUseCase = fetchPhotosetUseCase
        self.decisionsStatsUseCase = decisionsStatsUseCase
        self.syncUseCase = syncUseCase
        self.coordinator = coordinator
    }

    func load() async {
        do {
            async let photosetResult = fetchPhotosetUseCase.execute(id: id)
            async let decisionsResult = decisionsStatsUseCase.execute(for: id)

            let (photoset, decisionsStats) = try await (photosetResult, decisionsResult)

            let approvedCount = decisionsStats.approved
            let rejectedCount = decisionsStats.rejected
            let pendingCount = photoset.photosCount - approvedCount - rejectedCount
            let progress = if photoset.photosCount > 0 {
                Double(approvedCount + rejectedCount) / Double(photoset.photosCount)
            } else {
                0.0
            }

            state = .content(Content(
                title: photoset.name,
                coverUrl: photoset.coverImageURL,
                photosCount: photoset.photosCount,
                approvedCount: approvedCount,
                rejectedCount: rejectedCount,
                pendingCount: pendingCount,
                progressPercentage: progress,
                syncBadge: SyncBadgeViewModel(from: photoset.syncStatus)
            ))
        } catch {
            state = .error
        }
    }

    func didTap() {
        coordinator.show(.photosetDetail(id))
    }

    func didLongPress() {
        Task {
            await syncUseCase.startOfflineSync()
        }
    }

    func prepareSync() async {
        // Debounce: if the card leaves the screen before this fires, SwiftUI
        // cancels the task and the disk scan never runs.
        try? await Task.sleep(for: .milliseconds(400))

        guard !Task.isCancelled else {
            return
        }

        await syncUseCase.loadCacheState()
    }
}
