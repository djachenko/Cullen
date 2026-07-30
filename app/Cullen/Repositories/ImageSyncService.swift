//
//  ImageSyncService.swift
//  Cullen
//
//  Data - image sync engine split across two protocols:
//  ImageDownloadService (fetch + schedule) and ImageCacheService (cache truth
//  + a broadcast hub of "this URL is now cached" events). One concrete actor
//  implements both for now; physical extraction can come later.
//

import Foundation
import Kingfisher


enum SyncPriority: Int, Comparable, CaseIterable {
    case low
    case normal
    case high

    static func < (lhs: SyncPriority, rhs: SyncPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}


enum CacheEvent {
    case cached(URL)
    case failed(URL) // exhausted retries — this URL won't be cached without a fresh request
}


protocol ImageDownloadService {
    func download(urls: [URL], with priority: SyncPriority) async
    func stop(urls: [URL]) async
}


protocol ImageCacheService {
    func isCached(url: URL) -> Bool

    // Scanning a whole photoset means thousands of disk hits — always off the
    // caller's thread, never one isCached at a time from a @MainActor type.
    func cached(among urls: [URL]) async -> Set<URL>

    func removeFromCache(urls: [URL]) async

    // Everything that lands in the cache is reported here by CullenImageCache,
    // whoever wrote it; consumers observe via events(). One broadcast, many taps.
    func report(cached url: URL) async
    func events() async -> AsyncStream<CacheEvent>
}


actor KingfisherImageSyncService {
    private let manager: KingfisherManager
    private let cache: CullenImageCache
    private let maxInFlight: Int
    private let maxAttempts: Int

    private var buckets: [SyncPriority: [URL]] = [:]
    private var priorityOf: [URL: SyncPriority] = [:]
    private var attempts: [URL: Int] = [:]
    private var inFlight: [URL: Task<Void, Never>] = [:]
    private var subscribers: [UUID: AsyncStream<CacheEvent>.Continuation] = [:]

    init(
        manager: KingfisherManager,
        cache: CullenImageCache,
        maxInFlight: Int = 6,
        maxAttempts: Int = 3
    ) {
        self.manager = manager
        self.cache = cache
        self.maxInFlight = maxInFlight
        self.maxAttempts = maxAttempts

        cache.delegate = self
    }
}


// MARK: ImageCacheDelegate

extension KingfisherImageSyncService: ImageCacheDelegate {
    nonisolated func imageCache(didStore url: URL) {
        Task {
            await report(cached: url)
        }
    }
}


// MARK: ImageDownloadService

extension KingfisherImageSyncService: ImageDownloadService {
    func download(urls: [URL], with priority: SyncPriority) {
        urls.forEach {
            enqueue($0, priority)
        }

        pump()
    }

    func stop(urls: [URL]) {
        urls.forEach {
            remove($0)
        }
    }
}


// MARK: ImageCacheService

extension KingfisherImageSyncService: ImageCacheService {
    nonisolated func isCached(url: URL) -> Bool {
        cache.isCached(forKey: url.cacheKey)
    }

    // Detached on purpose: the scan is long and synchronous, so it must not run
    // on the main actor (it would freeze the feed) nor on this actor (it would
    // stall the download pump for its whole duration).
    nonisolated func cached(among urls: [URL]) async -> Set<URL> {
        await Task.detached(priority: .utility) { [self] in
            urls.reduce(into: Set<URL>()) { cached, url in
                if isCached(url: url) {
                    cached.insert(url)
                }
            }
        }.value
    }

    func removeFromCache(urls: [URL]) async {
        for url in urls {
            await withCheckedContinuation { continuation in
                cache.removeImage(forKey: url.cacheKey) {
                    continuation.resume()
                }
            }
        }
    }

    func report(cached url: URL) {
        broadcast(.cached(url))
    }

    func events() -> AsyncStream<CacheEvent> {
        let (stream, continuation) = AsyncStream<CacheEvent>.makeStream()
        let id = UUID()

        subscribers[id] = continuation

        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }

        return stream
    }
}


// MARK: Queue

private extension KingfisherImageSyncService {
    func enqueue(_ url: URL, _ priority: SyncPriority) {
        guard !isCached(url: url) else {
            return
        }

        // Уже качается — приоритет запоминаем, но очередь не трогаем.
        guard inFlight[url] == nil else {
            priorityOf[url] = priority

            return
        }

        if let current = priorityOf[url] {
            guard current != priority else {
                return
            }

            buckets[current]?.removeAll { $0 == url }
        }

        priorityOf[url] = priority
        buckets[priority, default: []].append(url)
    }

    func remove(_ url: URL) {
        if let priority = priorityOf[url] {
            buckets[priority]?.removeAll { $0 == url }
        }

        priorityOf[url] = nil
        attempts[url] = nil
        inFlight[url]?.cancel()
        inFlight[url] = nil
    }
}


// MARK: Admission

private extension KingfisherImageSyncService {
    func pump() {
        while inFlight.count < maxInFlight,
              let url = nextPending() {
            start(url)
        }
    }

    // Priorities come from CaseIterable, not from buckets.keys — dictionary key
    // order is undefined, so it can't tell us which bucket is the highest.
    // The inner loop drains entries that are already in flight so a stale one
    // doesn't send us down to a lower priority with work still waiting here.
    func nextPending() -> URL? {
        for priority in SyncPriority.allCases.reversed() {
            while let url = buckets[priority]?.first {
                buckets[priority]?.removeFirst()

                if inFlight[url] == nil {
                    return url
                }
            }
        }

        return nil
    }

    func start(_ url: URL) {
        inFlight[url] = Task {
            let success = await perform(url)

            finished(url, success: success)
        }
    }

    // Kingfisher owns the caching: it stores under the same keys the display
    // path uses, and skips the download outright when the image is already
    // cached. Decoding happens inside the downloader either way, so routing
    // through the manager costs nothing extra — but its memory copy would
    // evict what the user is actually looking at, hence the expired lifetime.
    func perform(_ url: URL) async -> Bool {
        do {
            _ = try await manager.retrieveImage(
                with: url,
                options: [.memoryCacheExpiration(.expired)]
            )

            return true
        } catch {
            return false
        }
    }

    func finished(_ url: URL, success: Bool) {
        inFlight[url] = nil

        if success {
            // No report here — the cache announces the write itself, so a
            // download and a plain display both arrive the same way.
            attempts[url] = nil
            priorityOf[url] = nil
        } else {
            let used = (attempts[url] ?? 0) + 1
            attempts[url] = used

            if used < maxAttempts, let priority = priorityOf[url] {
                buckets[priority, default: []].append(url) // retry — back of its bucket
            } else {
                attempts[url] = nil
                priorityOf[url] = nil
                broadcast(.failed(url))
            }
        }

        pump()
    }

    func broadcast(_ event: CacheEvent) {
        subscribers.values.forEach { $0.yield(event) }
    }

    func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }
}
