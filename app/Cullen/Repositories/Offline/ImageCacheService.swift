//
//  ImageCacheService.swift
//  Cullen
//
//  Created by justin on 4/8/26.
//

import Foundation
import Kingfisher


protocol ImageCacheService: Sendable {
    func isCached(url: URL) -> Bool

    // Scanning a whole photoset means thousands of disk hits — always off the
    // caller's thread, never one isCached at a time from a @MainActor type.
    func cachedSubset(among urls: [URL]) async -> Set<URL>

    func removeFromCache(urls: [URL]) async
}


// Не актор: собственного изменяемого состояния здесь нет. Kingfisher'овский
// кэш потокобезопасен сам, а рассылкой владеет хаб — изолировать нечего, и
// await на каждый isCached был бы платой ни за что.
final class ImageCacheServiceImpl: Sendable {
    private let cache: CullenImageCache
    private let publisher: any SyncEventPublisher

    init(cache: CullenImageCache, publisher: any SyncEventPublisher) {
        self.cache = cache
        self.publisher = publisher
    }
}


// MARK: ImageCacheDelegate

// Единственный источник .cached: любая запись в кэш — и наша загрузка, и
// картинка, показанная при листании — приходит сюда и дальше в хаб.
extension ImageCacheServiceImpl: ImageCacheDelegate {
    func imageCache(didStore url: URL) {
        Task { [publisher] in
            await publisher.post(.cached(url))
        }
    }
}


// MARK: ImageCacheService

extension ImageCacheServiceImpl: ImageCacheService {
    func isCached(url: URL) -> Bool {
        cache.isCached(forKey: url.cacheKey)
    }

    // Concurrent on purpose: the scan is long and synchronous, so it must not run
    // on the main actor — it would freeze the feed for its whole duration.
    @concurrent
    func cachedSubset(among urls: [URL]) async -> Set<URL> {
        Set(urls.filter { isCached(url: $0) })
    }

    // Kingfisher's IO queue is serial anyway — the group only saves waiting on
    // each callback in turn.
    @concurrent
    func removeFromCache(urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            urls.forEach { url in
                group.addTask { [cache] in
                    try? await cache.removeImage(forKey: url.cacheKey)
                }
            }
        }
    }
}
