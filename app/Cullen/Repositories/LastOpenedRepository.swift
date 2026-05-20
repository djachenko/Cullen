//
//  LastOpenedRepository.swift
//  Cullen
//

import Foundation


protocol LastOpenedRepository {
    func record(id: PhotosetId) async
    func allLastOpened() async -> [PhotosetId: Date]
}


actor UserDefaultsLastOpenedRepository: LastOpenedRepository {
    private static let defaultsKey = "cullen.lastOpened"

    private var cache: [String: Date]?

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func record(id: PhotosetId) {
        var data = loaded()
        data[id.description] = Date()
        cache = data

        defaults.set(data, forKey: Self.defaultsKey)
    }

    func allLastOpened() -> [PhotosetId: Date] {
        Dictionary(
            uniqueKeysWithValues: loaded().map { (.string($0.key), $0.value) }
        )
    }

    private func loaded() -> [String: Date] {
        if let cache {
            return cache
        }

        let raw = defaults.dictionary(forKey: Self.defaultsKey) as? [String: Date] ?? [:]
        cache = raw

        return raw
    }
}
