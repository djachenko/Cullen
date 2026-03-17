//
//  PhotosetDetailViewModel.swift
//  Cullen
//
//  Presentation Layer - Photoset Detail ViewModel
//

import Foundation
import SwiftUI
import Combine

// MARK: - PhotosetDetailViewModel

@MainActor
final class PhotosetDetailViewModel: ObservableObject {
    @Published var state: PhotosetDetailState = .initial
    @Published var activeFilters: Set<PhotoFilter> = Set(PhotoFilter.allCases)
    @Published var aspectRatio: Double = 3.0 / 2.0

    var filteredPhotos: [Photo] {
        guard let photos else {
            return []
        }


        if activeFilters == Set(PhotoFilter.allCases) {
            return photos
        }

        return photos.filter { photo in
            activeFilters.contains { $0.matches(decision: photo.decision) }
        }
    }

    var title: String {
        photosetInfo.title
    }

    var coverImageURL: URL? {
        photosetInfo.coverUrl
    }

    private let coordinator: Coordinator
    private let photosetInfo: PhotosetInfo
    private let fetchPhotosetUseCase: FetchPhotosUseCase

    private var photos: [Photo]?

    private lazy var task = Task {
        try await fetchPhotosetUseCase.execute(id: photosetInfo.id)
    }

    init(
        coordinator: Coordinator,
        photosetInfo: PhotosetInfo,
        fetchPhotosetUseCase: FetchPhotosUseCase
    ) {
        self.coordinator = coordinator
        self.photosetInfo = photosetInfo
        self.fetchPhotosetUseCase = fetchPhotosetUseCase
    }

    func loadPhotos() async {
        state = .loading

        do {
            self.photos = try await task.value

            state = .content(filteredPhotos.map { photo in
                PhotoGridCellViewModel(
                    id: photo.id,
                    imageURL: photo.url,
                    decision: .mock,
                ) { [weak self] in
                    self?.didTap(photo: photo)
                }
            })
        }
        catch is FetchPhotosUseCaseImpl.Error {
            state = .error(message: "No photoset")
        }
        catch {
            state = .error(message: "Exception")
        }
    }

    func toggleFilter(_ filter: PhotoFilter) {
        if activeFilters.contains(filter) {
            guard activeFilters.count > 1 else { return }
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
    }

    func isFilterActive(_ filter: PhotoFilter) -> Bool {
        activeFilters.contains(filter)
    }
}

private extension PhotosetDetailViewModel {
    func didTap(photo: Photo) {
        coordinator.show(
            .photoViewer(
                photos: filteredPhotos,
                startIndex: filteredPhotos.firstIndex(of: photo) ?? .zero
            )
        )
    }
}

// MARK: - Supporting Types

enum PhotosetDetailState {
    case initial
    case loading
    case content(PhotosetDetailContent)
    case error(message: String)
}

typealias PhotosetDetailContent = [PhotoGridCellViewModel]
