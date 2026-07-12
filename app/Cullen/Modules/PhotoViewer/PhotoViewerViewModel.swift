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
                logger?.notice("currentIndex \(oldValue) → \(currentIndex) clamped to \(clamped)")
                currentIndex = clamped
                return
            }

            logger?.debug("currentIndex \(oldValue) → \(currentIndex) [\(currentPhoto.id)]")
        }
    }
    @Published var compassViewModel: SwipeCompassViewModel?
    @Published var decisions: [PhotoId: Decision] = [:]
    @Published var settings: ViewerSettings

    // MARK: - Internal Properties

    let photos: [Photo]
    let logger: Logger?

    // MARK: - Private Properties

    private let photosetId: PhotosetId
    private let swipeHandler: SwipeGestureHandler
    private let saveDecisionUseCase: SaveDecisionUseCase
    private let loadDecisionsUseCase: LoadDecisionsUseCase
    private let viewerSettingsRepository: ViewerSettingsRepository

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
        viewerSettingsRepository: ViewerSettingsRepository,
        logger: Logger?,
    ) {
        self.photosetId = photosetId
        self.photos = photos
        self.currentIndex = startIndex
        self.logger = logger
        self.swipeHandler = swipeHandler
        self.saveDecisionUseCase = saveDecisionUseCase
        self.loadDecisionsUseCase = loadDecisionsUseCase
        self.viewerSettingsRepository = viewerSettingsRepository
        self.settings = viewerSettingsRepository.load(for: photosetId)
    }

    // MARK: - Public Methods

    func loadDecisions() async {
        decisions = (try? await loadDecisionsUseCase.execute(for: photosetId)) ?? [:]
    }

    func commitSwipe(_ direction: SwipeDirection) {
        logger?.debug("commitSwipe \(String(describing: direction)) at index \(currentIndex)")

        switch direction {
            case .up:
                goToNext()
            case .down:
                goToPrevious()
            default:
                if let decision = Decision(direction: direction) {
                    applyDecision(decision)
                }
        }
    }

    func cancelSwipe() {}

    func goToNext() {
        guard hasNext else {
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex += 1
        }
    }

    func goToPrevious() {
        guard hasPrevious else {
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            currentIndex -= 1
        }
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

    func cycleViewerMode() {
        let modes = ViewerMode.allCases

        guard let currentModeIndex = modes.firstIndex(of: settings.mode) else {
            return
        }

        let nextIndex = (currentModeIndex + 1) % modes.count

        settings.mode = modes[nextIndex]
        viewerSettingsRepository.save(settings, for: photosetId)
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


private extension PhotoViewerViewModel {
    func applyDecision(_ decision: Decision) {
        decisions[currentPhoto.id] = decision

        Task {
            try? await saveDecisionUseCase.execute(
                photoId: currentPhoto.id,
                decision: decision,
                in: photosetId
            )
        }

        guard hasNext else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else {
                return
            }

            logger?.debug("deferred advance from index \(currentIndex)")

            withAnimation(.easeInOut(duration: 0.25)) {
                self.currentIndex += 1
            }
        }
    }
}


extension Decision {
    init?(direction: SwipeDirection) {
        switch direction {
            case .left:
                self = .rejected
            case .right:
                self = .approved
            default:
                return nil
        }
    }
}
