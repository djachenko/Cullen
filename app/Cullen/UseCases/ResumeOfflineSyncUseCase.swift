//
//  ResumeOfflineSyncUseCase.swift
//  Cullen
//
//  Domain - picks up the photosets marked for offline on a previous run and
//  starts downloading whatever is missing.
//

import Foundation


// A closure rather than a resolver: the domain asks for "the sync of this
// photoset" without learning how instances are keyed or shared.
typealias PhotosetSyncProvider = @MainActor (PhotosetId) -> PhotosetSyncUseCase


protocol ResumeOfflineSyncUseCase {
    func execute() async
}


final class ResumeOfflineSyncUseCaseImpl {
    private let desiredStore: DesiredSyncStore
    private let syncProvider: PhotosetSyncProvider

    init(desiredStore: DesiredSyncStore, syncProvider: @escaping PhotosetSyncProvider) {
        self.desiredStore = desiredStore
        self.syncProvider = syncProvider
    }
}


extension ResumeOfflineSyncUseCaseImpl: ResumeOfflineSyncUseCase {
    // Each sync enqueues into the download service and can then be released —
    // the download outlives the use case that started it.
    func execute() async {
        for id in await desiredStore.all() {
            await syncProvider(id).startOfflineSync()
        }
    }
}
