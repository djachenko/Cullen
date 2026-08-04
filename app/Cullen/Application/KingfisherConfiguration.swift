//
//  KingfisherConfiguration.swift
//  Cullen
//
//  Created by justin on 17/3/26.
//

import Kingfisher
import Foundation
import SwinjectAutoregistration

enum KingfisherConfiguration {
    static func configure() {
        let manager = KingfisherManager.shared
        KingfisherConfiguration.configure(downloader: manager.downloader)

        manager.defaultOptions = [
            .processingQueue(.dispatch(DispatchQueue.global(qos: .userInitiated))),
            .cacheOriginalImage,
            .transition(.fade(0.15)),
        ]

        manager.cache = KingfisherConfiguration.cache()
    }

    private static func configure(downloader: ImageDownloader) {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 4

        downloader.sessionConfiguration = config
        downloader.downloadTimeout = .minutes(2)
    }

    private static func cache() -> ImageCache {
        // Displayed images must land in our cache too — that's how casual
        // scrolling feeds the same progress as an explicit sync.
        let cache = Cullen.resolver ~> ImageCache.self
        cache.diskStorage.config.expiration = .days(30)
        cache.diskStorage.config.sizeLimit = .gb(16)

        return cache
    }
}


extension UInt {
    static func gb(_ size: UInt) -> Self {
        return size * .mb(1024)
    }

    static func mb(_ size: UInt) -> Self {
        return size * .kb(1024)
    }

    static func kb(_ size: UInt) -> Self {
        return size * 1024
    }
}
