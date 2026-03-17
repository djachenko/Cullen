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
