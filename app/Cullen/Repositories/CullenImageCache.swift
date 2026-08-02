//
//  CullenImageCache.swift
//  Cullen
//
//  Data - ImageCache that reports every write. Both entry points are covered:
//  store() is the display path (KingfisherManager after showing an image),
//  storeToDisk() is our sync path (raw bytes, no decode). Neither calls the
//  other, so hooking both catches every way an image lands in the cache —
//  no matter who wrote it, and with nothing to wire at the call site.
//

import Foundation
import Kingfisher


protocol ImageCacheDelegate: AnyObject, Sendable {
    func imageCache(didStore url: URL)
}


final class CullenImageCache: ImageCache {
    // Same name as ImageCache.default — keeps pointing at the existing cache directory.
    static let shared = CullenImageCache(name: "default")

    weak var delegate: (any ImageCacheDelegate)?

    // Reporting happens in the completion handler, not right after super:
    // storeToDisk hops onto an IO queue, so the file isn't there yet when the
    // call returns and an isCached check would still say no.
    override func store(
        _ image: KFCrossPlatformImage,
        original: Data? = nil,
        forKey key: String,
        options: KingfisherParsedOptionsInfo,
        toDisk: Bool = true,
        completionHandler: (@Sendable (CacheStoreResult) -> Void)? = nil
    ) {
        super.store(
            image,
            original: original,
            forKey: key,
            options: options,
            toDisk: toDisk
        ) { [weak self] result in
            completionHandler?(result)
            self?.notify(key)
        }
    }

    override func storeToDisk(
        _ data: Data,
        forKey key: String,
        processorIdentifier identifier: String = "",
        forcedExtension: String? = nil,
        expiration: StorageExpiration? = nil,
        callbackQueue: CallbackQueue = .untouch,
        completionHandler: (@Sendable (CacheStoreResult) -> Void)? = nil
    ) {
        super.storeToDisk(
            data,
            forKey: key,
            processorIdentifier: identifier,
            forcedExtension: forcedExtension,
            expiration: expiration,
            callbackQueue: callbackQueue
        ) { [weak self] result in
            completionHandler?(result)
            self?.notify(key)
        }
    }
}


private extension CullenImageCache {
    func notify(_ key: String) {
        guard let url = URL(string: key) else {
            return
        }

        delegate?.imageCache(didStore: url)
    }
}
