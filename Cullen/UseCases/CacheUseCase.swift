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

    func cacheRatio(photoset: PhotosetId) async throws -> Double {
        let urls = try await photoURLs(for: photoset)

        guard !urls.isEmpty else {
            return 0
        }

        let cachedCount = await withTaskGroup(of: Bool.self) { group in
            for url in urls {
                group.addTask { [cacheService] in
                    cacheService.isCached(url: url)
                }
            }

            return await group.reduce(0) { $0 + ($1 ? 1 : 0) }
        }

        return Double(cachedCount) / Double(urls.count)
    }
}


private extension CacheUseCaseImpl {
    func photoURLs(for photoset: PhotosetId) async throws -> [URL] {
        try await photosetsRepository
            .getPhotoset(id: photoset)
            .photos
            .map(\.url)
    }
}
