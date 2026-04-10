//
//  CacheUseCase.swift
//  Cullen
//
//  Domain - Cache operations at photoset level
//

import Foundation


protocol CacheUseCase {
    func prefetch(photoset: PhotosetId) async throws -> AsyncStream<PrefetchEvent>
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
}


private extension CacheUseCaseImpl {
    func photoURLs(for photoset: PhotosetId) async throws -> [URL] {
        try await photosetsRepository
            .getPhotoset(id: photoset)
            .photos
            .map(\.url)
    }
}
