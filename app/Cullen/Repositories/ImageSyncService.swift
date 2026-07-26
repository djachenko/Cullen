//
//  ImageSyncService.swift
//  Cullen
//
//  Data - image sync engine: keys + priorities, own admission scheduler
//  over a single shared Kingfisher ImageDownloader.
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


protocol ImageSyncService {
    func download(urls: [URL], with priority: SyncPriority) async
    func stop(urls: [URL]) async
    func removeFromCache(urls: [URL]) async

    func isCached(url: URL) -> Bool

    func completions() async -> AsyncStream<URL>
}


actor KingfisherImageSyncService: ImageSyncService {
    private let downloader: ImageDownloader
    private let cache: ImageCache
    private let maxInFlight: Int

    private var buckets: [SyncPriority: [URL]] = [:]
    private var priorityOf: [URL: SyncPriority] = [:]
    private var inFlight: [URL: Task<Void, Never>] = [:]
    private var subscribers: [UUID: AsyncStream<URL>.Continuation] = [:]

    init(downloader: ImageDownloader = .default, cache: ImageCache = .default, maxInFlight: Int = 6) {
        self.downloader = downloader
        self.cache = cache
        self.maxInFlight = maxInFlight
    }

    nonisolated func isCached(url: URL) -> Bool {
        cache.isCached(forKey: url.cacheKey)
    }

    func download(urls: [URL], with priority: SyncPriority) {
        for url in urls {
            enqueue(url, priority)
        }

        pump()
    }

    func stop(urls: [URL]) {
        for url in urls {
            remove(url)
        }
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

    func completions() -> AsyncStream<URL> {
        let (stream, continuation) = AsyncStream<URL>.makeStream()
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
        inFlight[url]?.cancel()
        inFlight[url] = nil
    }
}


// MARK: Admission

private extension KingfisherImageSyncService {
    func pump() {
        while inFlight.count < maxInFlight, let url = nextPending() {
            start(url)
        }
    }

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
            try? await perform(url)
            await finished(url)
        }
    }

    func perform(_ url: URL) async throws {
        let result = try await downloader.downloadImage(with: url)

        try await cache.storeToDisk(result.originalData, forKey: url.cacheKey)
    }

    func finished(_ url: URL) {
        inFlight[url] = nil
        priorityOf[url] = nil

        broadcast(url)
        pump()
    }
}


// MARK: Subscribers

private extension KingfisherImageSyncService {
    func broadcast(_ url: URL) {
        for continuation in subscribers.values {
            continuation.yield(url)
        }
    }

    func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }
}
