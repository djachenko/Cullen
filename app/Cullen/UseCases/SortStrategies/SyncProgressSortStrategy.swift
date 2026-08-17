//
//  SyncProgressSortStrategy.swift
//  Cullen
//

final class SyncProgressSortStrategy: PhotosetSortStrategy {
    private let store: CachedRatioStore

    init(store: CachedRatioStore) {
        self.store = store
    }

    func sorted(ids: [PhotosetId], isAscending: Bool) async throws -> [PhotosetId] {
        let ratios = await store.ratios(for: ids)

        return ids.sorted(by: { ratios[$0] ?? .zero }, reverse: !isAscending)
    }
}
