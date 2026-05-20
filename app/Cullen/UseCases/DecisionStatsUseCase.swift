//
//  DecisionsStatsUseCase.swift
//  Cullen
//
//  Created by justin on 7/5/26.
//

struct DecisionsStats {
    let total: Int
    let approved: Int
    let rejected: Int

    var pending: Int {
        total - (approved + rejected)
    }

    var progress: Double {
        if total != 0 {
            Double(approved + rejected) / Double(total)
        } else {
            0
        }
    }
}

protocol DecisionsStatsUseCase {
    func execute(for photosetId: PhotosetId) async throws -> DecisionsStats
}


final class DecisionsStatsUseCaseImpl {
    private let decisionsUseCase: LoadDecisionsUseCase
    private let fetchPhotosetUseCase: FetchPhotosetUseCase

    init(decisionsUseCase: LoadDecisionsUseCase, fetchPhotosetUseCase: FetchPhotosetUseCase) {
        self.decisionsUseCase = decisionsUseCase
        self.fetchPhotosetUseCase = fetchPhotosetUseCase
    }
}


extension DecisionsStatsUseCaseImpl: DecisionsStatsUseCase {
    func execute(for photosetId: PhotosetId) async throws -> DecisionsStats {
        async let decisionsMappingResult = decisionsUseCase.execute(for: photosetId)
        async let photosetResult = fetchPhotosetUseCase.execute(id: photosetId)

        let (decisionsMapping, photoset) = try await (decisionsMappingResult, photosetResult)

        let decisions = decisionsMapping.values

        return DecisionsStats(
            total: photoset.photosCount,
            decisions: decisions
        )
    }
}


private extension DecisionsStats {
    init(total: Int, decisions: any Collection<Decision>) {
        let approved = decisions.filter { $0 == .approved }
        let rejected = decisions.filter { $0 == .rejected }

        self.init(
            total: total,
            approved: approved.count,
            rejected: rejected.count
        )
    }
}
