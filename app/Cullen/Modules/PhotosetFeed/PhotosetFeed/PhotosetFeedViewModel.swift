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
    @Published var selectedSortOption: PhotosetSortOption = .default
    @Published var sortDirection: SortDirection = PhotosetSortOption.default.defaultDirection

    var sortOptions = PhotosetSortOption.allCases.map { SortOptionDisplayModel(option: $0) }

    private let fetchPhotosetsUseCase: FetchPhotosetsUseCase
    private let sortPhotosetsUseCase: SortPhotosetsUseCase
    private let getStatisticsUseCase: GetPhotosetStatisticsUseCase
    private let exportLogsUseCase: ExportLogsUseCase
    private let preferences: PhotosetFeedPreferences

    private var cancellables = Set<AnyCancellable>()

    init(
        fetchPhotosetsUseCase: FetchPhotosetsUseCase,
        sortPhotosetsUseCase: SortPhotosetsUseCase,
        getStatisticsUseCase: GetPhotosetStatisticsUseCase,
        exportLogsUseCase: ExportLogsUseCase,
        preferences: PhotosetFeedPreferences,
    ) {
        self.fetchPhotosetsUseCase = fetchPhotosetsUseCase
        self.sortPhotosetsUseCase = sortPhotosetsUseCase
        self.getStatisticsUseCase = getStatisticsUseCase
        self.exportLogsUseCase = exportLogsUseCase
        self.preferences = preferences

        selectedSortOption = preferences.sortOption
        sortDirection = preferences.sortDirection

        setupBindings()
    }

    var logExport: LogExport {
        let filename = "Cullen-\(Date().formatted(.iso8601.dateSeparator(.dash).timeSeparator(.omitted))).log"

        return LogExport(filename: filename) { [weak self] in
            guard let data = await self?.exportLogsUseCase.execute() else {
                throw CancellationError()
            }

            return data
        }
    }

    func loadPhotosets() async {
        state = .loading

        do {
            async let idsTask = fetchPhotosetsUseCase.execute()
            async let statisticsTask = getStatisticsUseCase.execute()

            let (ids, statistics) = try await (idsTask, statisticsTask)
            let sorted = try await sortPhotosetsUseCase.execute(
                ids: ids,
                option: selectedSortOption,
                direction: sortDirection
            )

            state = .content(content: PhotosetFeedContent(
                photosetIds: sorted,
                statistics: StatisticsDisplayModel(from: statistics),
            ))
        } catch {
            state = .error(message: "Failed to load photo sets: \(error.localizedDescription)")
        }
    }

    func didSelectSortOption(_ option: PhotosetSortOption) {
        if option == selectedSortOption {
            sortDirection.toggle()
        } else {
            selectedSortOption = option
        }
    }
}

private extension PhotosetFeedViewModel {
    func setupBindings() {
        $selectedSortOption
            .dropFirst()
            .sink { [weak self] option in
                self?.sortDirection = option.defaultDirection
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($selectedSortOption, $sortDirection)
            .dropFirst()
            .sink { [weak self] option, direction in
                self?.preferences.sortOption = option
                self?.preferences.sortDirection = direction
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3($searchText, $selectedSortOption, $sortDirection)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
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
