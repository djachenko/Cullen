//
//  ImageCacheService.swift
//  Cullen
//
//  Domain - Image cache service protocol
//

import Kingfisher
import Foundation


enum PrefetchEvent {
    case progress(completed: Int, total: Int)
    case finished
}


typealias CacheKey = URL


protocol ImageCacheService {
    func startPrefetch(urls: [CacheKey]) -> AsyncStream<PrefetchEvent>

    func isCached(url: CacheKey) -> Bool
}


final class KingfisherImageCacheService {
    private let cache: ImageCache
    private let fileManager: FileManager

    private var prefetcher: ImagePrefetcher?

    init(cache: ImageCache, fileManager: FileManager) {
        self.cache = cache
        self.fileManager = fileManager
    }

    deinit {
        cancelPrefetch()
    }
}


extension KingfisherImageCacheService: ImageCacheService {
    func startPrefetch(urls: [CacheKey]) -> AsyncStream<PrefetchEvent> {
        cancelPrefetch()

        let total = urls.count

        guard total > 0 else {
            return AsyncStream { $0.finish() }
        }

        return AsyncStream { continuation in
            let prefetcher = ImagePrefetcher(
                urls: urls,
                progressBlock: { skipped, failed, completed in
                    let done = skipped.count + failed.count + completed.count

                    continuation.yield(.progress(
                        completed: done,
                        total: total
                    ))
                },
                completionHandler: { _, _, _ in
                    continuation.yield(.finished)
                    continuation.finish()
                }
            )

            self.prefetcher = prefetcher

            continuation.onTermination = { [weak self] _ in
                self?.cancelPrefetch()
            }

            prefetcher.start()
        }
    }

    func isCached(url: CacheKey) -> Bool {
        cache.isCached(forKey: url.cacheKey)
    }
}


private extension KingfisherImageCacheService {
    func cancelPrefetch() {
        prefetcher?.stop()
        prefetcher = nil
    }
}
