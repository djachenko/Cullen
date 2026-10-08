//
//  SortPhotosetsUseCase.swift
//  Cullen
//

import Foundation


protocol SortPhotosetsUseCase {
    func execute(ids: [PhotosetId], option: PhotosetSortOption, direction: SortDirection) async throws -> [PhotosetId]
}


final class SortPhotosetsUseCaseImpl: SortPhotosetsUseCase {
    private let repository: PhotosetsRepository
    private let decisionsStatsUseCase: DecisionsStatsUseCase
    private let lastOpenedRepository: LastOpenedRepository

    init(
        repository: PhotosetsRepository,
        decisionsStatsUseCase: DecisionsStatsUseCase,
        lastOpenedRepository: LastOpenedRepository
    ) {
        self.repository = repository
        self.decisionsStatsUseCase = decisionsStatsUseCase
        self.lastOpenedRepository = lastOpenedRepository
    }

    func execute(ids: [PhotosetId], option: PhotosetSortOption, direction: SortDirection) async throws -> [PhotosetId] {
        let photosets = try await fetchPhotosets(ids: ids)

        let photosetsById = Dictionary(uniqueKeysWithValues: photosets.map { ($0.id, $0) })

        func sortedIds<T: Comparable>(by key: (PhotosetId) -> T) -> [PhotosetId] {
            var sorted = ids.sorted { key($0) }

            if direction == .descending {
                sorted.reverse()
            }

            return sorted
        }

        return switch option {
            case .recent:
                sortedIds { photosetsById[$0]?.date ?? .distantPast }
            case .name:
                sortedIds { photosetsById[$0]?.name ?? "" }
            case .progress:
                try await {
                    let progressMapping = try await fetchProgress(ids: ids)

                    return sortedIds { progressMapping[$0] ?? .zero }
                }()
            case .photoCount:
                sortedIds { photosetsById[$0]?.photosCount ?? .zero }
            case .lastOpened:
                await {
                    let lastOpened = await lastOpenedRepository.allLastOpened()

                    return sortedIds { lastOpened[$0] ?? .distantPast }
                }()
        }
    }
}


private extension SortPhotosetsUseCaseImpl {
    func fetchPhotosets(ids: [PhotosetId]) async throws -> [Photoset] {
        try await withThrowingTaskGroup(of: Photoset.self) { group in
            for id in ids {
                group.addTask { try await self.repository.getPhotoset(id: id) }
            }

            var result: [Photoset] = []

            for try await photoset in group {
                result.append(photoset)
            }

            return result
        }
    }

    func fetchProgress(ids: [PhotosetId]) async throws -> [PhotosetId: Double] {
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
