//
//  DesiredSyncStore.swift
//  Cullen
//
//  Data - persists which photosets the user wants kept offline, so a sync
//  can be resumed across app launches.
//

import Foundation


protocol DesiredSyncStore {
    func add(_ id: PhotosetId) async
    func remove(_ id: PhotosetId) async
    func all() async -> [PhotosetId]
}


actor UserDefaultsDesiredSyncStore: DesiredSyncStore {
    private enum Constants {
        static let defaultsKey = "cullen.desiredSync"
    }

    private lazy var cache = {
        let photosetIds: [PhotosetId] = if let persistedIds = defaults.stringArray(forKey: Constants.defaultsKey) {
            persistedIds.map { .string($0) }
        } else {
            []
        }

        return Set(photosetIds)
    }()

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func add(_ id: PhotosetId) {
        cache.insert(id)

        persist()
    }

    func remove(_ id: PhotosetId) {
        cache.remove(id)

        persist()
    }

    func all() -> [PhotosetId] {
        Array(cache)
    }

    private func persist() {
        defaults.set(cache.map { $0.description }, forKey: Constants.defaultsKey)
    }
}
