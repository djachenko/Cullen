//
//  ProgressSortStrategy.swift
//  Cullen
//

final class ProgressSortStrategy: PhotosetSortStrategy {
    private let decisionsStatsUseCase: DecisionsStatsUseCase

    init(decisionsStatsUseCase: DecisionsStatsUseCase) {
        self.decisionsStatsUseCase = decisionsStatsUseCase
    }

    func sorted(ids: [PhotosetId], isAscending: Bool) async throws -> [PhotosetId] {
        let progress = try await progress(ids: ids)

        return ids.sorted(by: { progress[$0] ?? .zero }, reverse: !isAscending)
    }
}


private extension ProgressSortStrategy {
    func progress(ids: [PhotosetId]) async throws -> [PhotosetId: Double] {
        try await withThrowingTaskGroup(of: (PhotosetId, Double).self) { group in
            for id in ids {
                group.addTask {
                    let stats = try await self.decisionsStatsUseCase.execute(for: id)

                    return (id, stats.progress)
                }
            }

            var result: [PhotosetId: Double] = [:]

            for try await (id, ratio) in group {
                result[id] = ratio
            }

            return result
        }
    }
}
