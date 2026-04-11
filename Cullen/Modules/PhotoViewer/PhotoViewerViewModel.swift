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
    @Published var dragOffset: CGPoint = .zero
    @Published var isUIVisible: Bool = true
    @Published var decisions: [PhotoId: Decision] = [:]

    // MARK: - Private Properties

    private let photos: [Photo]

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

    /// Определяет направление свайпа по текущему drag offset
    var activeSwipeDirection: SwipeDirection? {
        let threshold: CGFloat = 40
        let x = dragOffset.x
        let y = dragOffset.y

        if abs(x) > abs(y) {
            if x > threshold  { return .right }
            if x < -threshold { return .left }
        } else {
            if y < -threshold { return .up }
            // Вниз — dismiss, не категория
        }
        return nil
    }

    /// Прогресс свайпа 0→1 для оверлея
    var swipeProgress: CGFloat {
        let threshold: CGFloat = 100
        let x = dragOffset.x
        let y = dragOffset.y
        let dominant = abs(x) > abs(y) ? abs(x) : abs(y)
        return min(1, dominant / threshold)
    }

    /// Rotation angle при свайпе влево/вправо
    var swipeRotation: Angle {
        .degrees(Double(dragOffset.x) / 20)
    }

    private var modifiedDecisions: [PhotoId: Decision] = [:]

    init(photos: [Photo], startIndex: Int) {
        self.photos = photos
        self.currentIndex = startIndex
    }

    // MARK: - Public Methods

    func toggleUI() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isUIVisible.toggle()
        }
    }

    func commitSwipe(_ direction: SwipeDirection) {
        decisions[currentPhoto.id] = direction.decision

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragOffset = .zero
        }

        // Переходим к следующему фото с небольшой задержкой
        if hasNext {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.currentIndex += 1
                }
            }
        }
    }

    func cancelSwipe() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = .zero
        }
    }

    func goToNext() {
        guard hasNext else { return }
//        animation in view model???
        withAnimation(.easeInOut(duration: 0.25)) { currentIndex += 1 }
    }

    func goToPrevious() {
        guard hasPrevious else { return }
        withAnimation(.easeInOut(duration: 0.25)) { currentIndex -= 1 }
    }

    func decision(for photo: Photo) -> Decision? {
        decisions[photo.id]
    }
}


extension PhotoViewerViewModel {
    static let actionMapping = [
        0.0..<45.0: Action.previous,
        45.0..<135.0: Action.approve,
        135.0..<225.0: Action.next,
        225.0..<315.0: Action.reject,
        315.0..<360.0: Action.previous,
        ]

    func didSwipe(angle: Double) {
        guard let action = PhotoViewerViewModel
            .actionMapping
            .first(where: { $0.key ~= angle })?
            .value else {
            return
        }

        let decision: Decision? = switch action {
            case .approve:
                    .approved
            case .reject:
                    .rejected
            default:
                nil
        }

        if let decision {
            modifiedDecisions[currentPhoto.id] = decision
        }

        if action == .previous {
            currentIndex -= 1
        } else {
            currentIndex += 1
        }
    }
}


enum Action {
    case previous
    case next
    case approve
    case reject
}

extension Int {
    func clamped(to range: Range<Int>) -> Int {
        if self < range.lowerBound {
            range.lowerBound
        } else if self > range.upperBound {
            range.upperBound
        } else {
            self
        }
    }
}
