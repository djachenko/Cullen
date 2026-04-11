//
//  CacheUseCase.swift
//  Cullen
//
//  Domain - Cache operations at photoset level
//

import Foundation


protocol CacheUseCase {
    func prefetch(photoset: PhotosetId) async throws -> AsyncStream<PrefetchEvent>

    func cacheRatio(photoset: PhotosetId) async throws -> Double

    func removeFromCache(photoset: PhotosetId) async throws
}


final class CacheUseCaseImpl {
    private let cacheService: ImageCacheService
    private let photosetsRepository: PhotosetsRepository

    init(cacheService: ImageCacheService, photosetsRepository: PhotosetsRepository) {
        self.cacheService = cacheService
        self.photosetsRepository = photosetsRepository
    }
}


extension CacheUseCaseImpl: CacheUseCase {
    func prefetch(photoset: PhotosetId) async throws -> AsyncStream<PrefetchEvent> {
        let urls = try await photoURLs(for: photoset)

        return cacheService.startPrefetch(urls: urls)
    }

    func removeFromCache(photoset: PhotosetId) async throws {
        try await parallelMap(photoset: photoset) { [cacheService] url in
            await cacheService.removeFromCache(url: url)
        }
    }

    func cacheRatio(photoset: PhotosetId) async throws -> Double {
        let results = try await parallelMap(photoset: photoset) { [cacheService] url in
            cacheService.isCached(url: url)
        }

        guard !results.isEmpty else {
            return 0
        }

        return Double(results.filter { $0 }.count) / Double(results.count)
    }
}


private extension CacheUseCaseImpl {
    @discardableResult
    func parallelMap<T: Sendable>(
        photoset: PhotosetId,
        _ body: @escaping @Sendable (URL) async -> T
    ) async throws -> [T] {
        let urls = try await photoURLs(for: photoset)

        guard !urls.isEmpty else {
            return []
        }

        return await withTaskGroup(of: T.self) { group in
            for url in urls {
                group.addTask { await body(url) }
            }

            return await group.reduce(into: []) { $0.append($1) }
        }
    }

    func photoURLs(for photoset: PhotosetId) async throws -> [URL] {
        try await photosetsRepository
            .getPhotoset(id: photoset)
            .photos
            .map(\.url)
    }
}
