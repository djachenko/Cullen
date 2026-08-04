//
//  PhotosetSyncUseCase.swift
//  Cullen
//
//  Domain - sync state of a single photoset. One instance per PhotosetId,
//  resolved from DI and shared across screens for as long as any of them holds
//  it. Owns nothing downloadable itself — drives ImageDownloadService and
//  derives its progress from ImageCacheService's broadcast (both explicit sync
//  and casual scrolling report there).
//

import Foundation
import Observation

// @MainActor on the protocol, not just the implementation: SwiftUI reads
// progress synchronously while evaluating a body, so the state has to be
// main-isolated — and a MainActor type cannot satisfy a non-isolated protocol.
@MainActor
protocol PhotosetSyncUseCase: AnyObject {
    var progress: Double? { get }
    var isSyncing: Bool { get }

    func loadCacheState() async
    func startOfflineSync() async
    func cancel() async
    func clear() async
    func window(_ urls: [URL]) async
    func set(isForeground: Bool) async
}


// Everything the use case knows, in one value. Nothing derived is stored here —
// see the extension below. Deliberately not Equatable: comparing it would mean
// comparing thousands of URLs on every cached photo.
private struct PhotosetSyncState {
    var photos = PhotoStatusMap()
    var isForeground = false
    var isDesired = false // the persisted intent to keep this set offline
    var isLoaded = false
}


// The whole dependency between the fields lives here and nowhere else. Adding a
// rule means adding a property, not editing every mutation site.
private extension PhotosetSyncState {
    // Left the queue once nothing is still being attempted. Счётчик ведёт сама
    // карта, так что это O(1) и на каждое событие считать не жалко.
    var isSettled: Bool {
        isLoaded && photos.count(of: .pending) == 0
    }

    var isSyncing: Bool {
        isDesired && !isSettled
    }

    var progress: Double? {
        guard isLoaded else {
            return nil
        }

        return if !photos.isEmpty {
            Double(photos.count(of: .cached)) / Double(photos.count)
        } else {
            1
        }
    }

    var priority: SyncPriority {
        if isForeground {
            .normal
        } else {
            .low
        }
    }

    // The only O(n) derivation, so reconcile() reads it on intent changes only.
    var pending: [URL] {
        photos.urls(with: .pending)
    }
}


@MainActor
@Observable
final class PhotosetSyncUseCaseImpl {
    // Доля закэшированного (nil пока baseline не посчитан). Растёт и от синка,
    // и от листания — источник правды кэш, не наши загрузки.
    private(set) var progress: Double?

    // Стоит ли сет в очереди на оффлайн. Независим от progress.
    private(set) var isSyncing = false

    private let photosetId: PhotosetId
    private let downloadService: ImageDownloadService
    private let cacheService: ImageCacheService
    private let eventSource: SyncEventSource
    private let photosetsRepository: PhotosetsRepository
    private let desiredStore: DesiredSyncStore

    // Единственная точка записи публичных свойств — рассинхрону взяться неоткуда.
    @ObservationIgnored private var state = PhotosetSyncState() {
        didSet {
            publish()
        }
    }

    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var observeTask: Task<Void, Never>?

    // nonisolated so the DI factory closure can build it without hopping.
    nonisolated init(
        photosetId: PhotosetId,
        downloadService: ImageDownloadService,
        cacheService: ImageCacheService,
        eventSource: SyncEventSource,
        photosetsRepository: PhotosetsRepository,
        desiredStore: DesiredSyncStore
    ) {
        self.photosetId = photosetId
        self.downloadService = downloadService
        self.cacheService = cacheService
        self.eventSource = eventSource
        self.photosetsRepository = photosetsRepository
        self.desiredStore = desiredStore
    }
}


// MARK: Commands

extension PhotosetSyncUseCaseImpl: PhotosetSyncUseCase {
    // Resolve the baseline and start observing without committing to anything.
    // Cheap to call repeatedly; progress stays nil until it lands.
    func loadCacheState() async {
        await load()
    }

    func startOfflineSync() async {
        await load()

        guard !state.photos.isEmpty else {
            return
        }

        let old = state

        state.photos.reset(.failed, to: .pending) // manual (re)start re-attempts what gave up
        state.isDesired = true

        await reconcile(from: old)
    }

    func cancel() async {
        let old = state

        state.isDesired = false

        await reconcile(from: old)
    }

    func clear() async {
        await cancel()
        await cacheService.removeFromCache(urls: state.photos.urls)

        state.photos = PhotoStatusMap(urls: state.photos.urls)
    }

    // Ephemeral by design: a boost belongs to the scroll position, not to the
    // set. It leaves no trace in the state, so nothing has to un-boost it.
    func window(_ urls: [URL]) async {
        guard state.isDesired else {
            return
        }

        let boosted = urls.filter { state.photos.status(of: $0) == .pending }

        guard !boosted.isEmpty else {
            return
        }

        await downloadService.download(urls: boosted, with: .high)
    }

    func set(isForeground: Bool) async {
        let old = state

        state.isForeground = isForeground

        await reconcile(from: old)
    }
}


// MARK: Loading

private extension PhotosetSyncUseCaseImpl {
    // The task is created and stored in one synchronous step, so concurrent
    // callers all await the same load instead of racing past a boolean flag.
    func load() async {
        let task = loadTask ?? Task { [weak self] in
            await self?.performLoad()
        }

        loadTask = task

        await task.value
    }

    func performLoad() async {
        guard let photoset = try? await photosetsRepository.getPhotoset(id: photosetId) else {
            loadTask = nil // не смогли — пусть следующий вызов попробует заново

            return
        }

        let keys = photoset.photos.map(\.url)
        let cached = await cacheService.cached(among: keys)
        let isDesired = await desiredStore.all().contains(photosetId)

        let old = state

        state.photos = PhotoStatusMap(urls: keys, cached: cached)
        state.isDesired = isDesired
        state.isLoaded = true

        observe()

        // old.isDesired is false here, so a set restored from the store reads as
        // a fresh commitment and reconcile picks the download back up.
        await reconcile(from: old)
    }

    func observe() {
        observeTask = observeTask ?? Task { [weak self] in
            guard let stream = await self?.eventSource.events() else {
                return
            }

            for await event in stream {
                guard let self else {
                    break
                }

                await handle(event)
            }
        }
    }

    func handle(_ event: SyncEvent) async {
        let old = state

        switch event {
            case .cached(let url):
                // Успех перебивает любой прежний статус, в том числе .failed.
                state.photos.set(.cached, for: url)

            case .failed(let url):
                guard state.photos.status(of: url) == .pending else {
                    return
                }

                state.photos.set(.failed, for: url)
        }

        await reconcile(from: old)
    }
}


// MARK: Effects

private extension PhotosetSyncUseCaseImpl {
    func publish() {
        if progress != state.progress {
            progress = state.progress
        }

        if isSyncing != state.isSyncing {
            isSyncing = state.isSyncing
        }
    }

    // Diffs the intent, not the resulting set: the comparisons are scalar, and
    // the O(n) pending list is only built on the branches that actually need it.
    // Everything that has to happen when the commitment changes happens here —
    // persistence and the engine are never touched from anywhere else.
    func reconcile(from old: PhotosetSyncState) async {
        if state.isSettled {
            state.isDesired = false
        }

        switch (old.isDesired, state.isDesired) {
            case (false, true):
                await desiredStore.add(photosetId)
                await downloadService.download(urls: state.pending, with: state.priority)

            case (true, false):
                await desiredStore.remove(photosetId)
                await downloadService.stop(urls: state.photos.urls)

            case (true, true) where old.priority != state.priority:
                await downloadService.download(urls: state.pending, with: state.priority)

            default:
                break
        }
    }
}
