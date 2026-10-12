//
//  LastOpenedSortStrategy.swift
//  Cullen
//

import Foundation


final class LastOpenedSortStrategy: PhotosetSortStrategy {
    private let repository: LastOpenedRepository

    init(repository: LastOpenedRepository) {
        self.repository = repository
    }

    func sorted(ids: [PhotosetId], isAscending: Bool) async throws -> [PhotosetId] {
        let lastOpened = await repository.allLastOpened()

        return ids.sorted(by: { lastOpened[$0] ?? .distantPast }, reverse: !isAscending)
    }
}
