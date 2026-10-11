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
    // the download outlives the use case that started it. In parallel: every
    // start loads its photoset and scans the cache first, and one set shouldn't
    // wait behind another's scan.
    func execute() async {
        let ids = await desiredStore.all()

        await withTaskGroup(of: Void.self) { [syncProvider] group in
            for id in ids {
                group.addTask {
                    await syncProvider(id).startOfflineSync()
                }
            }
        }
    }
}
