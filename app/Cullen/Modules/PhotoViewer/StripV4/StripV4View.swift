//
//  StripV4View.swift
//  Cullen
//

import SwiftUI
import Kingfisher

// MARK: - StripV4View

struct StripV4View: View {

    @ObservedObject var viewModel: PhotoViewerViewModel

    @State private var activeId: PhotoId?
    @State private var dragOffset: CGFloat = 0

    private enum Layout {
        static let cardSpacing: CGFloat = 20
        static let defaultAspectRatio: CGFloat = 3.0 / 2.0
        static let swipeFraction: CGFloat = 1.0 / 3.0
        static let velocityWeight: CGFloat = 0.1
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            let cardHeight = cardWidth / Layout.defaultAspectRatio
            let edgeInset = max((geometry.size.height - cardHeight) / 2, 0)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: Layout.cardSpacing) {
                    Color.clear.frame(height: edgeInset)

                    ForEach(viewModel.photos) { photo in
                        cardView(
                            photo: photo,
                            cardWidth: cardWidth,
                        )
                        .frame(height: cardHeight)
                    }

                    Color.clear.frame(height: edgeInset)
                }
                .scrollTargetLayout()
            }
            .background(Color.black)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $activeId, anchor: .center)
            .onAppear {
                UIScrollView.appearance().decelerationRate = .fast

                guard viewModel.photos.indices.contains(viewModel.currentIndex) else {
                    return
                }

                activeId = viewModel.photos[viewModel.currentIndex].id
            }
            .onDisappear {
                UIScrollView.appearance().decelerationRate = .normal
            }
        }
        .ignoresSafeArea()
        .onChange(of: activeId) { _, id in
            guard let id,
                  let index = viewModel.photos.firstIndex(where: { $0.id == id }),
                  viewModel.currentIndex != index else {
                return
            }

            viewModel.currentIndex = index
        }
        .onChange(of: viewModel.currentIndex) { _, newIndex in
            guard viewModel.photos.indices.contains(newIndex) else {
                return
            }

            let id = viewModel.photos[newIndex].id

            guard id != activeId else {
                return
            }

            activeId = id
        }
    }
}

// MARK: - Card

private extension StripV4View {
    @ViewBuilder
    func cardView(photo: Photo, cardWidth: CGFloat) -> some View {
        let isActive = photo.id == activeId
        let swipeThreshold = cardWidth * Layout.swipeFraction

        let cardDragOffset: CGFloat = if isActive {
            dragOffset
        } else {
            0
        }

        let swipeProgress = min(abs(cardDragOffset) / swipeThreshold, 1)

        ZStack {
            underlay
                .opacity(swipeProgress)

            StripV4CardView(
                photo: photo,
                decision: viewModel.decisions[photo.id] ?? .pending,
            )
            .offset(x: cardDragOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .id(photo.id)
        .onHorizontalDrag(
            onChanged: { x in
                guard photo.id == activeId else {
                    return
                }

                dragOffset = x
            },
            onEnded: { translation, velocity in
                guard photo.id == activeId else {
                    return
                }
                
                handleSwipeEnd(
                    translation: translation,
                    velocity: velocity,
                    threshold: swipeThreshold
                )
            }
        )
    }

    var underlay: some View {
        HStack {
            StripV4UnderlayView(decision: .approved)
                .frame(maxWidth: .infinity)

            Color.clear
                .frame(maxWidth: .infinity)

            StripV4UnderlayView(decision: .rejected)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Swipe

private extension StripV4View {
    func handleSwipeEnd(translation: CGFloat, velocity: CGFloat, threshold: CGFloat) {
        let projected = translation + velocity * Layout.velocityWeight

        snapBack()

        guard abs(projected) > threshold else {
            return
        }

        let direction: SwipeDirection = if projected > 0 {
            .right
        } else {
            .left
        }
        viewModel.commitSwipe(direction)
    }

    func snapBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = 0
        }
    }
}
