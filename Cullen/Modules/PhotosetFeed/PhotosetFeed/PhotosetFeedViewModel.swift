//
//  PhotosetFeedViewModel.swift
//  Cullen
//
//  Presentation Layer - Thin ViewModel (UI State Only)
//

import Foundation
import SwiftUI
import Combine


@MainActor
final class PhotosetFeedViewModel: ObservableObject {
    @Published var state: PhotosetFeedState = .initial
    @Published var searchText: String = ""
    @Published var selectedSortOption: PhotosetSortOption = .recent

    private let fetchPhotosetsUseCase: FetchPhotosetsUseCase
    private let getStatisticsUseCase: GetPhotosetStatisticsUseCase

    private var cancellables = Set<AnyCancellable>()

    var sortOptions: [SortOptionDisplayModel] {
        PhotosetSortOption.allCases.map { SortOptionDisplayModel(option: $0) }
    }

    init(
        fetchPhotosetsUseCase: FetchPhotosetsUseCase,
        getStatisticsUseCase: GetPhotosetStatisticsUseCase,
    ) {
        self.fetchPhotosetsUseCase = fetchPhotosetsUseCase
        self.getStatisticsUseCase = getStatisticsUseCase

        setupBindings()
    }

    func loadPhotosets() async {
        state = .loading

        do {
            async let idsTask = fetchPhotosetsUseCase.execute()
            async let statisticsTask = getStatisticsUseCase.execute()

            let (ids, statistics) = try await (idsTask, statisticsTask)

            state = .content(content: PhotosetFeedContent(
                photosetIds: ids,
                statistics: StatisticsDisplayModel(from: statistics),
            ))
        } catch {
            state = .error(message: "Failed to load photo sets: \(error.localizedDescription)")
        }
    }
}

private extension PhotosetFeedViewModel {
    func setupBindings() {
        Publishers.CombineLatest($searchText, $selectedSortOption)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                Task { await self?.loadPhotosets() }
            }
            .store(in: &cancellables)
    }
}

struct PhotosetFeedContent {
    let photosetIds: [PhotosetId]
    let statistics: StatisticsDisplayModel
}

enum PhotosetFeedState {
    case initial
    case loading
    case content(content: PhotosetFeedContent)
    case error(message: String)
}
