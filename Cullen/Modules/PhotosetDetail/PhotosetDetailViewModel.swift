//
//  PhotosetDetailViewModel.swift
//  Cullen
//
//  Presentation Layer - Photoset Detail ViewModel
//

import Foundation
import SwiftUI
import Combine


@MainActor
final class PhotosetDetailViewModel: ObservableObject {
    @Published var state: PhotosetDetailState = .initial
    @Published var aspectRatio: Double = 3.0 / 2.0

    var title: String {
        cachedPhotoset?.name ?? ""
    }

    private let coordinator: Coordinator
    private let fetchPhotosUseCase: FetchPhotosUseCase
    private let loadDecisionsUseCase: LoadDecisionsUseCase

    private let photosetTask: Task<Photoset, Error>
    private lazy var photosTask = Task {
        let photoset = try await photosetTask.value
        return try await fetchPhotosUseCase.execute(id: photoset.id)
    }
    private var decisionsTask: Task<[PhotoId: Decision], Error> {
        Task {
            let photoset = try await photosetTask.value
            return try await loadDecisionsUseCase.execute(for: photoset.id)
        }
    }

    private var cachedPhotoset: Photoset?
    private var photos: [Photo]?

    nonisolated private init(
        photosetTask: Task<Photoset, Error>,
        coordinator: Coordinator,
        fetchPhotosUseCase: FetchPhotosUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase
    ) {
        self.photosetTask = photosetTask
        self.coordinator = coordinator
        self.fetchPhotosUseCase = fetchPhotosUseCase
        self.loadDecisionsUseCase = loadDecisionsUseCase
    }

//    convenience init(
//        photoset: Photoset,
//        coordinator: Coordinator,
//        fetchPhotosUseCase: FetchPhotosUseCase,
//        loadDecisionsUseCase: LoadDecisionsUseCase
//    ) {
//        self.init(
//            photosetTask: Task { photoset },
//            coordinator: coordinator,
//            fetchPhotosUseCase: fetchPhotosUseCase,
//            loadDecisionsUseCase: loadDecisionsUseCase
//        )
//    }

    nonisolated convenience init(
        id: PhotosetId,
        coordinator: Coordinator,
        fetchPhotosetUseCase: FetchPhotosetUseCase,
        fetchPhotosUseCase: FetchPhotosUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase
    ) {
        self.init(
            photosetTask: Task {
                try await fetchPhotosetUseCase.execute(id: id)
            },
            coordinator: coordinator,
            fetchPhotosUseCase: fetchPhotosUseCase,
            loadDecisionsUseCase: loadDecisionsUseCase
        )
    }

    func loadPhotos() async {
        state = .loading

        do {
            async let photosetResult = photosetTask.value
            async let photosResult = photosTask.value
            async let decisionsResult = decisionsTask.value

            let (photoset, photos, decisions) = try await (photosetResult, photosResult, decisionsResult)
            cachedPhotoset = photoset
            self.photos = photos

            state = .content(photos.map { photo in
                PhotoGridCellViewModel(
                    id: photo.id,
                    imageURL: photo.url,
                    decision: decisions[photo.id] ?? .pending,
                ) { [weak self] in
                    self?.didTap(photo: photo)
                }
            })
        } catch is FetchPhotosUseCaseImpl.Error {
            state = .error(message: "No photoset")
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }

    func toggleFilter(_ filter: PhotoFilter) {
        // TODO: restore filtering
    }

    func isFilterActive(_ filter: PhotoFilter) -> Bool {
        true
    }
}

private extension PhotosetDetailViewModel {
    func didTap(photo: Photo) {
        guard let photos, let photoset = cachedPhotoset else { return }
        coordinator.show(
            .photoViewer(
                photos: photos,
                startIndex: photos.firstIndex(of: photo) ?? .zero,
                photosetId: photoset.id
            )
        )
    }
}

enum PhotosetDetailState {
    case initial
    case loading
    case content(PhotosetDetailContent)
    case error(message: String)
}

typealias PhotosetDetailContent = [PhotoGridCellViewModel]
