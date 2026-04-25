//
//  StripV5View.swift
//  Cullen
//

import SwiftUI

struct StripV5View: View {

    @ObservedObject var viewModel: PhotoViewerViewModel

    @State private var activeId: PhotoId?
    @State private var swipeProgress: CGFloat = 0
    @State private var zoomScale: CGFloat = 1
    @State private var isScrolling = false

    @StateObject private var zoomControl = ZoomControl()

    private enum Layout {
        static let cardSpacing: CGFloat = 20
        static let defaultAspectRatio: CGFloat = 3.0 / 2.0
        static let swipeFraction: CGFloat = 1.0 / 3.0
        static let velocityWeight: CGFloat = 0.1
    }

    var body: some View {
        GeometryReader { geometry in
            let cardHeight = geometry.size.width / Layout.defaultAspectRatio
            let edgeInset = max((geometry.size.height - cardHeight) / 2, 0)

            ZStack {
                strip(geometry: geometry, edgeInset: edgeInset)
                zoomOverlay
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
        .onChange(of: viewModel.currentIndex) { _, _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                activeId = viewModel.currentPhoto.id
            }
        }
    }
}

// MARK: - Strip

private extension StripV5View {

    func strip(geometry: GeometryProxy, edgeInset: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: Layout.cardSpacing) {
                ForEach(viewModel.photos) { photo in
                    card(photo: photo, geometry: geometry)
                        .frame(height: geometry.size.width / Layout.defaultAspectRatio)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .id(photo.id)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.vertical, edgeInset, for: .scrollContent)
        .background(Color.black)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $activeId, anchor: .center)
        .scrollDisabled(zoomScale > 1)
        .onScrollPhaseChange { _, new in
            isScrolling = new != .idle
        }
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
}

// MARK: - Cards

private extension StripV5View {

    @ViewBuilder
    func card(photo: Photo, geometry: GeometryProxy) -> some View {
        if photo.id == activeId {
            activeCard(photo: photo, geometry: geometry)
        } else {
            StripV4CardView(
                photo: photo,
                decision: viewModel.decisions[photo.id] ?? .pending
            )
        }
    }

    func activeCard(photo: Photo, geometry: GeometryProxy) -> some View {
        let threshold = geometry.size.width * Layout.swipeFraction

        return ZStack {
            HStack {
                StripV4UnderlayView(decision: .approved)
                    .frame(width: threshold)

                Spacer()

                StripV4UnderlayView(decision: .rejected)
                    .frame(width: threshold)
            }
            .opacity(min(abs(swipeProgress), 1))

            StripV4CardView(
                photo: photo,
                decision: viewModel.decisions[photo.id] ?? .pending
            )
            .offset(x: threshold * swipeProgress)
        }
        .gestureLayer(captures: { _ in zoomScale == 1 }) {
            GestureTap(count: 2) { location in
                zoomControl.zoom(to: 3, screenAnchor: location, animated: true)
            }
            GesturePan(
                filter: .horizontal,
                when: { !isScrolling },
                onChanged: { translation in
                    swipeProgress = translation / threshold
                },
                onEnded: { translation, velocity in
                    handleSwipeEnd(translation: translation, velocity: velocity, threshold: threshold)
                }
            )
            GesturePinch(onChanged: { scale, anchor in
                zoomControl.zoom(to: scale, screenAnchor: anchor)
                if scale > 1 {
                    zoomScale = scale
                }
            })
        }
    }
}

// MARK: - Zoom overlay

private extension StripV5View {

    var zoomOverlay: some View {
        ZoomableImageView(
            viewModel: ZoomableImageViewModel(
                url: viewModel.currentPhoto.url,
                onZoomScaleChange: { scale in
                    zoomScale = scale
                }
            ),
            externalControl: zoomControl
        )
        .allowsHitTesting(zoomScale > 1)
        .opacity(zoomScale > 1 ? 1 : 0)
        .ignoresSafeArea()
    }
}

// MARK: - Swipe

private extension StripV5View {

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
            swipeProgress = 0
        }
    }
}
