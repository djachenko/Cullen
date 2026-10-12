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


// Актор здесь по делу: очередь и дескрипторы правятся и снаружи (с главного
// актора), и из завершений загрузок. Приоритет живёт в очереди, пока URL
// ждёт, в дескрипторе — пока качается, и возвращается в очередь на ретрае.
actor ImageDownloadServiceImpl {
    struct Limits {
        let maxInFlight: Int
        let maxAttempts: Int
    }

    // Заводится заново на каждой попытке и живёт до успеха, последней неудачной
    // попытки или stop — то есть описывает то, что качается или ждёт ретрая.
    private struct UrlDescriptor {
        let id = UUID()
        let priority: SyncPriority
        var attempts: Int
        var task: Task<Void, Never>?
    }

    private let manager: KingfisherManager
    private let publisher: any SyncEventPublisher
    private let limits: Limits

    private var queue = PriorityQueue()
    private var descriptors: [URL: UrlDescriptor] = [:]
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
    func download(urls: [URL], with priority: SyncPriority) {
        queue.enqueue(urls, priority: priority)

        pump()
    }

    // Снимает и очередь, и текущие загрузки: отмена задачи рвёт загрузку
    // в Kingfisher, докачивания не будет.
    func stop(urls: [URL]) {
        queue.remove(urls)

        urls.forEach {
            descriptors[$0]?.task?.cancel()
            descriptors.removeValue(forKey: $0)
        }
    }
}


// MARK: Queue

private extension ImageDownloadServiceImpl {
    // Очередь не знает, что качается: URL, поставленный во время загрузки,
    // выкидывается здесь. Уже скачанное отсекает сам Kingfisher: загрузка
    // вырождается в чтение из кэша.
    func next() -> (url: URL, priority: SyncPriority)? {
        while let entry = queue.dequeue() {
            guard descriptors[entry.url]?.task == nil else {
                continue
            }

            return entry
        }

        return nil
    }
}


// MARK: Downloading

private extension ImageDownloadServiceImpl {
    func pump() {
        while inFlight < limits.maxInFlight,
              let entry = next() {
            start(entry.url, priority: entry.priority)
        }
    }

    func start(_ url: URL, priority: SyncPriority) {
        let oldDescriptor = descriptors[url] // in case there was old attempt

        var descriptor = UrlDescriptor(
            priority: priority,
            attempts: oldDescriptor?.attempts ?? 0
        )

        descriptor.task = Task { [weak self, id = descriptor.id] in
            await self?.run(url, id: id)
        }

        descriptors[url] = descriptor
        inFlight += 1
    }

    func run(_ url: URL, id: UUID) async {
        let succeeded = await retrieve(url)

        inFlight -= 1

        defer {
            pump()
        }

        // Пока качали, URL могли снять или снять и поставить заново — тогда
        // дескриптор уже чужой, и докладывать не о чем.
        guard descriptors[url]?.id == id else {
            return
        }

        guard !succeeded else {
            // Об успехе расскажет сам кэш, когда допишет файл. Здесь молчим,
            // чтобы загрузка и обычный показ картинки приходили одним путём.
            descriptors.removeValue(forKey: url)

            return
        }

        descriptors[url]?.task = nil
        descriptors[url]?.attempts += 1

        if let descriptor = descriptors[url],
           descriptor.attempts < limits.maxAttempts {
            // Запрошенный заново во время загрузки URL уже стоит в очереди
            // с последним приоритетом — возвращать ему старый незачем.
            if !queue.contains(url) {
                queue.enqueue(url, priority: descriptor.priority)
            }
        } else {
            descriptors.removeValue(forKey: url)

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
                options: [
                    .memoryCacheExpiration(.expired),
                ]
            )

            return true
        } catch {
            return false
        }
    }
}
