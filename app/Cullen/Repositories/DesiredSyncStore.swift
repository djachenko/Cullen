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
    private static let defaultsKey = "cullen.desiredSync"

    private var cache: Set<String>?

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func add(_ id: PhotosetId) {
        var data = loaded()
        data.insert(id.description)
        persist(data)
    }

    func remove(_ id: PhotosetId) {
        var data = loaded()
        data.remove(id.description)
        persist(data)
    }

    func all() -> [PhotosetId] {
        loaded().map { .string($0) }
    }

    private func persist(_ data: Set<String>) {
        cache = data
        defaults.set(Array(data), forKey: Self.defaultsKey)
    }

    private func loaded() -> Set<String> {
        if let cache {
            return cache
        }

        let raw = Set(defaults.stringArray(forKey: Self.defaultsKey) ?? [])
        cache = raw

        return raw
    }
}
