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
    let id = UUID()
    var priority: SyncPriority
    var attempts = 0
    var task: Task<Void, Never>?
}


// Актор здесь по делу: очередь и дескрипторы правятся и снаружи (с главного
// актора), и из завершений загрузок. Очередь знает, что ждёт и с каким
// приоритетом; дескрипторы — текущую загрузку и число попыток.
actor ImageDownloadServiceImpl {
    struct Limits {
        let maxInFlight: Int
        let maxAttempts: Int
    }

    private let manager: KingfisherManager
    private let cacheService: any ImageCacheService
    private let publisher: any SyncEventPublisher
    private let limits: Limits

    private var queue = PriorityQueue()
    private var descriptions: [URL: UrlDescriptor] = [:]
    private var inFlight = 0

    init(
        manager: KingfisherManager,
        cacheService: any ImageCacheService,
        publisher: any SyncEventPublisher,
        limits: Limits
    ) {
        self.manager = manager
        self.cacheService = cacheService
        self.publisher = publisher
        self.limits = limits
    }
}


extension ImageDownloadServiceImpl: ImageDownloadService {
    func download(urls: [URL], with priority: SyncPriority) {
        urls.forEach {
            enqueue($0, priority: priority)
        }

        pump()
    }

    // Снимает и очередь, и текущие загрузки: отмена задачи рвёт загрузку
    // в Kingfisher, докачивания не будет.
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

        descriptions[url, default: UrlDescriptor(priority: priority)].priority = priority

        // Уже качается — очередь не трогаем, иначе получим вторую загрузку
        // того же файла. Приоритет из дескриптора пригодится для ретрая.
        if descriptions[url]?.task == nil {
            queue.enqueue(url, priority: priority)
        }
    }

    func remove(_ url: URL) {
        queue.remove(url)
        descriptions[url]?.task?.cancel()
        descriptions.removeValue(forKey: url)
    }

    // Между постановкой и стартом картинку мог закэшировать показ — тогда
    // качать нечего, а .cached уже ушёл из кэша.
    func next() -> URL? {
        while let url = queue.dequeue() {
            guard !cacheService.isCached(url: url) else {
                descriptions.removeValue(forKey: url)

                continue
            }

            return url
        }

        return nil
    }
}


// MARK: Downloading

private extension ImageDownloadServiceImpl {
    func pump() {
        while inFlight < limits.maxInFlight,
              let url = next() {
            start(url)
        }
    }

    func start(_ url: URL) {
        guard let id = descriptions[url]?.id else {
            return
        }

        inFlight += 1

        descriptions[url]?.task = Task { [weak self] in
            await self?.run(url, id: id)
        }
    }

    func run(_ url: URL, id: UUID) async {
        let succeeded = await retrieve(url)

        inFlight -= 1

        defer {
            pump()
        }

        // Пока качали, URL могли снять или снять и поставить заново — тогда
        // дескриптор уже чужой, и докладывать не о чем.
        guard descriptions[url]?.id == id else {
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

        if (descriptions[url]?.attempts ?? 0) < limits.maxAttempts,
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
