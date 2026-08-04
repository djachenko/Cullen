//
//  ImageDownloadService.swift
//  Cullen
//
//  Created by justin on 4/8/26.
//

import Foundation
import Kingfisher


protocol ImageDownloadService: Sendable {
    func download(urls: [URL], with priority: SyncPriority) async
    func stop(urls: [URL]) async
}


private struct UrlDescriptor {
    var priority: SyncPriority
    var attempts = 0
    var task: Task<Void, Never>?
}


// Актор здесь по делу: очередь и дескрипторы правятся и снаружи (с главного
// актора), и из завершений загрузок. Словарь дескрипторов — источник правды,
// очередь лишь подсказывает порядок.
actor ImageDownloadServiceImpl {
    private let manager: KingfisherManager
    private let cacheService: any ImageCacheService
    private let publisher: any SyncEventPublisher
    private let maxInFlight: Int
    private let maxAttempts: Int

    private var queue = PriorityQueue()
    private var descriptions: [URL: UrlDescriptor] = [:]
    private var inFlight = 0

    init(
        manager: KingfisherManager,
        cacheService: any ImageCacheService,
        publisher: any SyncEventPublisher,
        maxInFlight: Int = 4,
        maxAttempts: Int = 3
    ) {
        self.manager = manager
        self.cacheService = cacheService
        self.publisher = publisher
        self.maxInFlight = maxInFlight
        self.maxAttempts = maxAttempts
    }
}


extension ImageDownloadServiceImpl: ImageDownloadService {
    func download(urls: [URL], with priority: SyncPriority) {
        urls.forEach {
            enqueue($0, priority: priority)
        }

        pump()
    }

    func stop(urls: [URL]) {
        urls.forEach {
            remove($0)
        }
    }
}


// MARK: Queue

private extension ImageDownloadServiceImpl {
    func enqueue(_ url: URL, priority: SyncPriority) {
        guard !cacheService.isCached(url: url) else {
            return
        }

        // Не было приоритета — URL новый, значит в очередь. Уже качается —
        // приоритет запоминаем, но очередь не трогаем, иначе получим вторую
        // загрузку того же файла.
        if descriptions[url]?.priority != priority,
           descriptions[url]?.task == nil {
            queue.enqueue(url, priority: priority)
        }

        descriptions[url, default: UrlDescriptor(priority: priority)].priority = priority
    }

    // Из очереди ничего не выковыривается: убитый дескриптор и есть надгробие,
    // мертвеца отсеет next() при съёме.
    func remove(_ url: URL) {
        descriptions[url]?.task?.cancel()
        descriptions.removeValue(forKey: url)
    }

    func next() -> URL? {
        while let entry = queue.dequeue() {
            // Дескриптора нет — URL сняли. Приоритет разошёлся — это старая
            // копия, живая лежит в другом бакете.
            guard descriptions[entry.url]?.priority == entry.priority else {
                continue
            }

            return entry.url
        }

        return nil
    }
}


// MARK: Downloading

private extension ImageDownloadServiceImpl {
    func pump() {
        while inFlight < maxInFlight,
              let url = next() {
            start(url)
        }
    }

    func start(_ url: URL) {
        inFlight += 1

        descriptions[url]?.task = Task { [weak self] in
            await self?.run(url)
        }
    }

    func run(_ url: URL) async {
        let succeeded = await retrieve(url)

        inFlight -= 1

        defer {
            pump()
        }

        // Пока качали, URL могли снять — тогда докладывать не о чем.
        guard descriptions[url] != nil else {
            return
        }

        guard !succeeded else {
            // Об успехе расскажет сам кэш, когда допишет файл. Здесь молчим,
            // чтобы загрузка и обычный показ картинки приходили одним путём.
            descriptions.removeValue(forKey: url)

            return
        }

        descriptions[url]?.task = nil
        descriptions[url]?.attempts += 1

        if (descriptions[url]?.attempts ?? 0) < maxAttempts,
           let priority = descriptions[url]?.priority {
            queue.enqueue(url, priority: priority)
        } else {
            descriptions.removeValue(forKey: url)

            await publisher.post(.failed(url))
        }
    }

    // Kingfisher owns the caching: it stores under the same keys the display
    // path uses, and skips the download outright when the image is already
    // cached. Decoding happens inside the downloader either way, so routing
    // through the manager costs nothing extra — but its memory copy would
    // evict what the user is actually looking at, hence the expired lifetime.
    nonisolated func retrieve(_ url: URL) async -> Bool {
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
}
