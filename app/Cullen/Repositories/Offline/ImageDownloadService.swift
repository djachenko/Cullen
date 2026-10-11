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
// актора), и из завершений загрузок. Очередь знает только порядок;
// дескрипторы — что нужно, текущую загрузку и число попыток.
actor ImageDownloadServiceImpl {
    struct Limits {
        let maxInFlight: Int
        let maxAttempts: Int
    }

    private let manager: KingfisherManager
    private let publisher: any SyncEventPublisher
    private let limits: Limits

    private var queue = PriorityQueue()
    private var descriptions: [URL: UrlDescriptor] = [:]
    private var inFlight = 0

    init(
        manager: KingfisherManager,
        publisher: any SyncEventPublisher,
        limits: Limits
    ) {
        self.manager = manager
        self.publisher = publisher
        self.limits = limits
    }
}


extension ImageDownloadServiceImpl: ImageDownloadService {
    // Дескриптор — это «URL нужен», приоритет из него пригодится для ретрая.
    func download(urls: [URL], with priority: SyncPriority) {
        urls.forEach {
            descriptions[$0, default: UrlDescriptor(priority: priority)].priority = priority
        }

        queue.enqueue(urls, priority: priority)

        pump()
    }

    // Снимает и очередь, и текущие загрузки: отмена задачи рвёт загрузку
    // в Kingfisher, докачивания не будет.
    func stop(urls: [URL]) {
        queue.remove(urls)

        urls.forEach {
            descriptions[$0]?.task?.cancel()
            descriptions.removeValue(forKey: $0)
        }
    }
}


// MARK: Queue

private extension ImageDownloadServiceImpl {
    // Очередь не знает, что качается: URL, поставленный во время загрузки,
    // выкидывается здесь — или потому что ещё качается, или потому что уже
    // скачан и дескриптора нет. Закэшированное отсекает сам Kingfisher:
    // загрузка вырождается в чтение из кэша.
    func next() -> URL? {
        while let url = queue.dequeue() {
            guard let descriptor = descriptions[url],
                  descriptor.task == nil else {
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
            queue.enqueue([url], priority: priority)
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
