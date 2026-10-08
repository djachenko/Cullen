//
//  PhotoStatusMap.swift
//  Cullen
//
//  Domain - статусы фотографий одного сета. Хранилище и счётчики приватные:
//  снаружи статус нельзя поменять мимо set(_:for:), поэтому счётчики не могут
//  разъехаться с картой, а URL не может оказаться в двух состояниях сразу.
//

import Foundation


enum PhotoSyncStatus {
    case pending
    case cached
    case failed // exhausted retries — won't be cached without a fresh request
}


struct PhotoStatusMap {
    let urls: [URL]
    private var statuses: [URL: PhotoSyncStatus]
    private var counts: [PhotoSyncStatus: Int]

    // Счётчики считаются один раз при построении, дальше только правятся.
    init(urls: [URL] = [], cached: Set<URL> = []) {
        self.urls = urls

        statuses = Dictionary(uniqueKeysWithValues: urls.map {
            let state: PhotoSyncStatus = if cached.contains($0) {
                .cached
            } else {
                .pending
            }

            return ($0, state)
        })

        counts = statuses.values.reduce(into: [:]) { counts, status in
            counts[status, default: 0] += 1
        }
    }
}


extension PhotoStatusMap {
    var count: Int {
        statuses.count
    }

    var isEmpty: Bool {
        statuses.isEmpty
    }

    func count(of status: PhotoSyncStatus) -> Int {
        counts[status] ?? 0
    }

    func contains(_ url: URL) -> Bool {
        statuses[url] != nil
    }

    func status(of url: URL) -> PhotoSyncStatus? {
        statuses[url]
    }

    // Порядок исходный — очередь загрузки идёт по сету сверху вниз.
    func urls(with status: PhotoSyncStatus) -> [URL] {
        urls.filter { statuses[$0] == status }
    }

    // Единственный способ поменять статус. Незнакомый URL игнорируется: карта
    // не растёт после init, иначе счётчик от init перестал бы что-то значить.
    mutating func set(_ status: PhotoSyncStatus, for url: URL) {
        guard let old = statuses[url],
              old != status else {
            return
        }

        statuses[url] = status
        counts[old, default: 0] -= 1
        counts[status, default: 0] += 1
    }

    mutating func reset(_ status: PhotoSyncStatus, to new: PhotoSyncStatus) {
        for url in urls(with: status) {
            set(new, for: url)
        }
    }
}
