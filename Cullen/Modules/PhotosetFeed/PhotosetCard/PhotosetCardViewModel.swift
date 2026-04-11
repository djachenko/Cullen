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

    private let fetchPhotosetUseCase: FetchPhotosetUseCase
    private let loadDecisionsUseCase: LoadDecisionsUseCase
    private let coordinator: Coordinator

    init(
        id: PhotosetId,
        fetchPhotosetUseCase: FetchPhotosetUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase,
        coordinator: Coordinator
    ) {
        self.id = id
        self.fetchPhotosetUseCase = fetchPhotosetUseCase
        self.loadDecisionsUseCase = loadDecisionsUseCase
        self.coordinator = coordinator
    }

    func load() async {
        do {
            print("PhotosetCardViewModel \(id)")

            async let photosetResult = fetchPhotosetUseCase.execute(id: id)
            async let decisionsResult = loadDecisionsUseCase.execute(for: id)

            let (photoset, decisions) = try await (photosetResult, decisionsResult)

            print("awaited \(id)")

            let approvedCount = decisions.values.count { $0 == .approved }
            let rejectedCount = decisions.values.count { $0 == .rejected }
            let pendingCount = photoset.photosCount - approvedCount - rejectedCount
            let progress = photoset.photosCount > 0
                ? Double(approvedCount + rejectedCount) / Double(photoset.photosCount)
                : 0

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
}
