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
    func all() async -> Set<PhotosetId>
}


actor UserDefaultsDesiredSyncStore  {
    private enum Constants {
        static let defaultsKey = "cullen.desiredSync"
    }

    private lazy var cache = {
        let photosetIds: [PhotosetId] = defaults.stringArray(forKey: Constants.defaultsKey)?
            .compactMap(PhotosetId.string) ?? []

        return Set(photosetIds)
    }()

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
}

extension UserDefaultsDesiredSyncStore: DesiredSyncStore {
    func add(_ id: PhotosetId) {
        cache.insert(id)

        persist()
    }

    func remove(_ id: PhotosetId) {
        cache.remove(id)

        persist()
    }

    func all() -> Set<PhotosetId> {
        cache
    }
}

private extension UserDefaultsDesiredSyncStore {
    func persist() {
        defaults.set(cache.map { $0.description }, forKey: Constants.defaultsKey)
    }
}
