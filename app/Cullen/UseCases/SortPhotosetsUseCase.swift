//
//  SortPhotosetsUseCase.swift
//  Cullen
//

protocol SortPhotosetsUseCase {
    func execute(ids: [PhotosetId], option: PhotosetSortOption, direction: SortDirection) async throws -> [PhotosetId]
}


final class SortPhotosetsUseCaseImpl: SortPhotosetsUseCase {
    private let strategies: [PhotosetSortOption: PhotosetSortStrategy]

    init(strategies: [PhotosetSortOption: PhotosetSortStrategy]) {
        self.strategies = strategies
    }

    func execute(ids: [PhotosetId], option: PhotosetSortOption, direction: SortDirection) async throws -> [PhotosetId] {
        guard let strategy = strategies[option] else {
            fatalError("No sort strategy registered for \(option)")
        }

        return try await strategy.sorted(ids: ids, isAscending: direction == .ascending)
    }
}
