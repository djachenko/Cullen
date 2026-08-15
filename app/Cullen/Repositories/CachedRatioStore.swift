//
//  CachedRatioStore.swift
//  Cullen
//
//  Data - persists the last-known cache ratio per photoset so the feed can
//  show a meaningful value immediately on the next launch, before the disk
//  scan for that photoset completes.
//

import Foundation


protocol CachedRatioStore {
    func ratio(for id: PhotosetId) async -> Double?
    func store(ratio: Double, for id: PhotosetId) async
    func remove(for id: PhotosetId) async
}


actor UserDefaultsCachedRatioStore: CachedRatioStore {
    private enum Constants {
        static let defaultsKey = "cullen.cachedRatio"
    }

    private var cache: [String: Double]
    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.cache = (defaults.dictionary(forKey: Constants.defaultsKey) as? [String: Double]) ?? [:]
    }

    func ratio(for id: PhotosetId) -> Double? {
        cache[id.description]
    }

    func store(ratio: Double, for id: PhotosetId) {
        cache[id.description] = ratio
        persist()
    }

    func remove(for id: PhotosetId) {
        cache[id.description] = nil
        persist()
    }

    private func persist() {
        defaults.set(cache, forKey: Constants.defaultsKey)
    }
}
