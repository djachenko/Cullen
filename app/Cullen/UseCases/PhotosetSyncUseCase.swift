//
//  PhotosetSyncUseCase.swift
//  Cullen
//
//  Domain - sync state of a single photoset. One long-lived instance per
//  PhotosetId (vended by PhotosetSyncRegistry), shared across screens.
//  Owns nothing downloadable itself — drives the keys-only ImageSyncService
//  and derives its state from broadcast completions.
//

import Foundation
import Observation


@MainActor
@Observable
final class PhotosetSyncUseCase {
    private(set) var state: PhotosetCacheState = .notCached

    private let photosetId: PhotosetId
    private let syncService: ImageSyncService
    private let photosetsRepository: PhotosetsRepository

    private var keys: [URL] = []
    private var keySet: Set<URL> = []
    private var done: Set<URL> = []
    private var isDownloading = false
    private var isForeground = false
    private var observeTask: Task<Void, Never>?

    init(
        photosetId: PhotosetId,
        syncService: ImageSyncService,
        photosetsRepository: PhotosetsRepository
    ) {
        self.photosetId = photosetId
        self.syncService = syncService
        self.photosetsRepository = photosetsRepository
    }
}


// MARK: Commands

extension PhotosetSyncUseCase {
    func start() async {
        await loadKeysIfNeeded()

        guard !keySet.isEmpty else {
            return
        }

        isDownloading = true
        observe()

        await syncService.download(urls: pending, with: priority)
        recompute()
    }

    func cancel() async {
        isDownloading = false

        await syncService.stop(urls: keys)
        recompute()
    }

    func clear() async {
        isDownloading = false

        await syncService.stop(urls: keys)
        await syncService.removeFromCache(urls: keys)

        done.removeAll()
        recompute()
    }

    func setForeground(_ on: Bool) async {
        isForeground = on

        guard isDownloading else {
            return
        }

        await syncService.download(urls: pending, with: priority)
    }
}


// MARK: Internals

private extension PhotosetSyncUseCase {
    var priority: SyncPriority {
        isForeground ? .normal : .low
    }

    var pending: [URL] {
        keys.filter { !done.contains($0) }
    }

    func loadKeysIfNeeded() async {
        guard keySet.isEmpty else {
            return
        }

        guard let photoset = try? await photosetsRepository.getPhotoset(id: photosetId) else {
            return
        }

        keys = photoset.photos.map(\.url)
        keySet = Set(keys)
        done = keySet.filter { syncService.isCached(url: $0) }

        recompute()
    }

    func observe() {
        guard observeTask == nil else {
            return
        }

        observeTask = Task { [weak self] in
            guard let stream = await self?.syncService.completions() else {
                return
            }

            for await url in stream {
                guard let self else {
                    break
                }

                guard keySet.contains(url), syncService.isCached(url: url) else {
                    continue
                }

                done.insert(url)
                recompute()
            }
        }
    }

    func recompute() {
        state = if keySet.isEmpty {
            .notCached
        } else if done.count == keySet.count {
            .synced
        } else if isDownloading {
            .syncing(progress: Double(done.count) / Double(keySet.count))
        } else {
            .notCached
        }
    }
}
