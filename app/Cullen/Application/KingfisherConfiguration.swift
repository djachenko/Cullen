//
//  KingfisherConfiguration.swift
//  Cullen
//
//  Created by justin on 17/3/26.
//

import Kingfisher
import Foundation

enum KingfisherConfiguration {
    static func configure() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 4
        KingfisherManager.shared.downloader.sessionConfiguration = config
        KingfisherManager.shared.downloader.downloadTimeout = .minutes(2)

        KingfisherManager.shared.defaultOptions = [
            .processingQueue(.dispatch(DispatchQueue.global(qos: .userInitiated))),
            .cacheOriginalImage,
            .transition(.fade(0.15)),
        ]

        ImageCache.default.diskStorage.config.expiration = .days(30)
        ImageCache.default.diskStorage.config.sizeLimit = 16 * 1024 * 1024 * 1024  // 2 GB
    }
}
