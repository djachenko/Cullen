//
//  PhotosetSyncUseCase.swift
//  Cullen
//
//  Domain - sync state of a single photoset. One long-lived instance per
//  PhotosetId (vended by PhotosetSyncRegistry), shared across screens.
//  Owns nothing downloadable itself — drives ImageDownloadService and derives
//  its progress from ImageCacheService's broadcast (both explicit sync and
//  casual scrolling report there).
//

import Foundation
import Observation


@MainActor
@Observable
final class PhotosetSyncUseCase {
    // Доля закэшированного (nil пока baseline не посчитан). Растёт и от синка,
    // и от листания — источник правды кэш, не наши загрузки.
    private(set) var progress: Double?

    // Стоит ли сет в очереди на оффлайн (committed). Независим от progress.
    private(set) var isSyncing = false

    private let photosetId: PhotosetId
    private let downloadService: ImageDownloadService
    private let cacheService: ImageCacheService
    private let photosetsRepository: PhotosetsRepository
    private let desiredStore: DesiredSyncStore

    private var keys: [URL] = []
    private var keySet: Set<URL> = []
    private var done: Set<URL> = []
    private var failed: Set<URL> = []
    private var isForeground = false
    private var loaded = false
    private var observeTask: Task<Void, Never>?

    init(
        photosetId: PhotosetId,
        downloadService: ImageDownloadService,
        cacheService: ImageCacheService,
        photosetsRepository: PhotosetsRepository,
        desiredStore: DesiredSyncStore
    ) {
        self.photosetId = photosetId
        self.downloadService = downloadService
        self.cacheService = cacheService
        self.photosetsRepository = photosetsRepository
        self.desiredStore = desiredStore
    }
}


// MARK: Commands

extension PhotosetSyncUseCase {
    // Resolve the baseline and start observing without downloading. Cheap to
    // call repeatedly; progress stays nil until it lands.
    func prepare() async {
        await loadKeysIfNeeded()
    }

    func start() async {
        await loadKeysIfNeeded()

        guard !keySet.isEmpty else {
            return
        }

        failed.removeAll() // manual (re)start re-attempts anything that gave up
        isSyncing = true
        await desiredStore.add(photosetId)

        await downloadService.download(urls: pending, with: priority)
    }

    func cancel() async {
        isSyncing = false

        await desiredStore.remove(photosetId)
        await downloadService.stop(urls: keys)
    }

    func clear() async {
        isSyncing = false

        await desiredStore.remove(photosetId)
        await downloadService.stop(urls: keys)
        await cacheService.removeFromCache(urls: keys)

        done.removeAll()
        failed.removeAll()
        recompute()
    }

    func window(_ urls: [URL]) async {
        guard isSyncing else {
            return
        }

        let boosted = urls.filter { keySet.contains($0) && !done.contains($0) }

        guard !boosted.isEmpty else {
            return
        }

        await downloadService.download(urls: boosted, with: .high)
    }

    func setForeground(_ on: Bool) async {
        isForeground = on

        guard isSyncing else {
            return
        }

        await downloadService.download(urls: pending, with: priority)
    }
}


// MARK: Internals

private extension PhotosetSyncUseCase {
    var priority: SyncPriority {
        isForeground ? .normal : .low
    }

    var pending: [URL] {
        keys.filter { !done.contains($0) && !failed.contains($0) }
    }

    func loadKeysIfNeeded() async {
        guard !loaded else {
            return
        }

        guard let photoset = try? await photosetsRepository.getPhotoset(id: photosetId) else {
            return
        }

        keys = photoset.photos.map(\.url)
        keySet = Set(keys)
        done = keySet.filter { cacheService.isCached(url: $0) }
        isSyncing = await desiredStore.all().contains(photosetId)
        loaded = true

        observe()
        recompute()
    }

    func observe() {
        guard observeTask == nil else {
            return
        }

        observeTask = Task { [weak self] in
            guard let stream = await self?.cacheService.events() else {
                return
            }

            for await event in stream {
                guard let self else {
                    break
                }

                switch event {
                    case .cached(let url):
                        guard keySet.contains(url), cacheService.isCached(url: url) else {
                            continue
                        }

                        done.insert(url)

                    case .failed(let url):
                        guard keySet.contains(url) else {
                            continue
                        }

                        failed.insert(url)
                }

                recompute()
                await drainIfSettled()
            }
        }
    }

    // Left the offline queue once every key is resolved — cached or given up.
    func drainIfSettled() async {
        guard isSyncing, done.count + failed.count == keySet.count else {
            return
        }

        isSyncing = false
        await desiredStore.remove(photosetId)
    }

    func recompute() {
        guard loaded else {
            progress = nil
            return
        }

        progress = keySet.isEmpty ? 1 : Double(done.count) / Double(keySet.count)
    }
}
