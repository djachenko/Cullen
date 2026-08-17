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
    func cached(among urls: [URL]) async -> Set<URL>

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

        cache.delegate = self
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

    // Detached on purpose: the scan is long and synchronous, so it must not run
    // on the main actor — it would freeze the feed for its whole duration.
    func cached(among urls: [URL]) async -> Set<URL> {
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
}
