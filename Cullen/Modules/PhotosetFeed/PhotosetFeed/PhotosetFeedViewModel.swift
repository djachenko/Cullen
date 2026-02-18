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

    private let coordinator: Coordinator

    private let fetchPhotosetsUseCase: FetchPhotosetsUseCaseProtocol
    private let getStatisticsUseCase: GetPhotosetStatisticsUseCaseProtocol

    private var cancellables = Set<AnyCancellable>()

    var sortOptions: [SortOptionDisplayModel] {
        PhotosetSortOption.allCases.map { SortOptionDisplayModel(option: $0) }
    }

    init(
        coordinator: Coordinator,
        fetchPhotosetsUseCase: FetchPhotosetsUseCaseProtocol,
        getStatisticsUseCase: GetPhotosetStatisticsUseCaseProtocol,
    ) {
        self.coordinator = coordinator
        self.fetchPhotosetsUseCase = fetchPhotosetsUseCase
        self.getStatisticsUseCase = getStatisticsUseCase

        setupBindings()
    }
    
    // MARK: - Actions (UI Events)
    
    func loadPhotosets() async {
        state = .loading

        do {
            async let photosetsTask = fetchPhotosetsUseCase.execute(
                sortBy: selectedSortOption,
                searchQuery: searchText
            )

            async let statisticsTask = getStatisticsUseCase.execute()

            let (photosets, statistics) = try await (photosetsTask, statisticsTask)

            state = .content(
                content: PhotosetFeedContent(
                    photosets: photosets.map { PhotosetCardViewModel(from: $0) },
                    statistics: StatisticsDisplayModel(from: statistics),
                )
            )
        } catch {
            state = .error(message: "Failed to load photo sets: \(error.localizedDescription)")
        }
    }
}

extension PhotosetFeedViewModel {
    func didTap(photoset: PhotosetCardViewModel) {
        coordinator.show(.photosetDetail(photoset))
    }
}

private extension PhotosetFeedViewModel {
    func setupBindings() {
        Publishers.CombineLatest(
            $searchText,
            $selectedSortOption
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _ in
            Task {
                await self?.loadPhotosets()
            }
        }
        .store(in: &cancellables)
    }
}

struct PhotosetFeedContent {
    let photosets: [PhotosetCardViewModel]
    let statistics: StatisticsDisplayModel
}

enum PhotosetFeedState {
    case initial
    case loading
    case content(content: PhotosetFeedContent)
    case error(message: String)
}
