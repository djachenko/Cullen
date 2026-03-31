//
//  PhotoViewerViewModel.swift
//  Cullen
//
//  Created by justin on 5/3/26.
//

import Combine
import Foundation
import CoreGraphics
import SwiftUI


@MainActor
final class PhotoViewerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentIndex: Int {
        didSet {
            let clamped = currentIndex.clamped(to: photos.indices)

            if clamped != currentIndex {
                currentIndex = clamped
            }
        }
    }
    @Published var compassViewModel: SwipeCompassViewModel?
    @Published var decisions: [PhotoId: Decision] = [:]

    // MARK: - Private Properties

    private let photosetId: PhotosetId
    private let photos: [Photo]
    private let swipeHandler: SwipeGestureHandler
    private let saveDecisionUseCase: SaveDecisionUseCase
    private let loadDecisionsUseCase: LoadDecisionsUseCase

    // MARK: - Computed Properties

    var currentPhoto: Photo {
        photos[currentIndex]
    }

    var totalCount: Int {
        photos.count
    }

    private var hasNext: Bool {
        currentIndex < photos.count - 1
    }

    private var hasPrevious: Bool {
        currentIndex > 0
    }

    init(
        photos: [Photo],
        startIndex: Int,
        photosetId: PhotosetId,
        swipeHandler: SwipeGestureHandler,
        saveDecisionUseCase: SaveDecisionUseCase,
        loadDecisionsUseCase: LoadDecisionsUseCase,
    ) {
        self.photosetId = photosetId
        self.photos = photos
        self.currentIndex = startIndex
        self.swipeHandler = swipeHandler
        self.saveDecisionUseCase = saveDecisionUseCase
        self.loadDecisionsUseCase = loadDecisionsUseCase
    }

    // MARK: - Public Methods

    func loadDecisions() async {
        decisions = (try? await loadDecisionsUseCase.execute(for: photosetId)) ?? [:]
    }

    func commitSwipe(_ direction: SwipeDirection) {
        if let decision = direction.decision {
            decisions[currentPhoto.id] = decision

            Task {
                try? await saveDecisionUseCase.execute(
                    photoId: currentPhoto.id,
                    decision: decision,
                    in: photosetId
                )
            }
        }

//        TODO: create delay
        switch direction {
            case .up:
//                TODO: Move to default
                goToNext()
            case .down:
                goToPrevious()
            default:
                

                if hasNext {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.currentIndex += 1
                        }
                    }
                }
        }
    }

    func cancelSwipe() {}

    func goToNext() {
        guard hasNext else { return }
        withAnimation(.easeInOut(duration: 0.25)) { currentIndex += 1 }
    }

    func goToPrevious() {
        guard hasPrevious else { return }
        withAnimation(.easeInOut(duration: 0.25)) { currentIndex -= 1 }
    }

    func resetDecision() {
        decisions[currentPhoto.id] = .pending

        Task {
            try? await saveDecisionUseCase.execute(
                photoId: currentPhoto.id,
                decision: .pending,
                in: photosetId
            )
        }
    }
}

extension PhotoViewerViewModel {
    func handle(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            if let (angle, progress) = swipeHandler.track(recognizer),
               let direction = SwipeDirection(angle: angle) {
                compassViewModel = SwipeCompassViewModel(activeDirection: direction, progress: progress)
            } else {
                compassViewModel = nil
            }

        case .ended, .cancelled:
            if let angle = swipeHandler.evaluate(recognizer),
               let direction = SwipeDirection(angle: angle) {
                commitSwipe(direction)
            } else {
                cancelSwipe()
            }
            compassViewModel = nil

        default:
            break
        }
    }
}
