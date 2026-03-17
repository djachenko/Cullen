//
//  PhotoViewerView.swift
//  Cullen
//
//  Created by justin on 22/2/26.
//

import SwiftUI

// MARK: - PhotoViewerView

struct PhotoViewerView: View {

    // MARK: - Constants

    private enum Layout {
        static let maxZoomScale: CGFloat = 5
        static let doubleTapZoomScale: CGFloat = 3
    }

    // MARK: - Properties

    @ObservedObject var viewModel: PhotoViewerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isUIVisible = true

    private let swipeHandler = SwipeGestureHandler()

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            photoView

            swipeOverlay
        }
        .navigationBarHidden(!isUIVisible)
        .navigationTitle("\(viewModel.currentIndex + 1) / \(viewModel.totalCount)")
        .navigationBarTitleDisplayMode(.inline)
        .statusBarHidden(!isUIVisible)
        .animation(.easeInOut(duration: 0.2), value: isUIVisible)
    }

    // MARK: - Photo View

    private var photoView: some View {
        ZoomableImageView(
            viewModel: ZoomableImageViewModel(
                url: viewModel.currentPhoto.url,
                maxZoomScale: Layout.maxZoomScale,
                doubleTapZoomScale: Layout.doubleTapZoomScale,
                onSingleTap: {
                    isUIVisible.toggle()
                },
                onPan: { recognizer in
                    switch recognizer.state {
                    case .changed:
                        viewModel.dragOffset = recognizer.translation(in: recognizer.view)
                    case .ended, .cancelled:
                        if let angle = swipeHandler.evaluate(recognizer),
                           let direction = SwipeDirection(angle: angle) {
                            viewModel.commitSwipe(direction)
                        } else {
                            viewModel.cancelSwipe()
                        }
                    default:
                        break
                    }
                }
            )
        )
        .ignoresSafeArea()
        .id(viewModel.currentIndex)
        .transition(.opacity)
    }

    // MARK: - Swipe Overlay

    private var swipeOverlay: some View {
        SwipeCompassView(
            activeDirection: viewModel.activeSwipeDirection,
            progress: viewModel.swipeProgress
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

import SwinjectAutoregistration

#Preview {
    NavigationStack {
        Cullen.resolver ~> (
            PhotoViewerView.self,
            arguments: (
                [
                    Photo(
                        id: "test",
                        url: URL(string: "https://sun9-38.userapi.com/s/v1/ig2/cMnRR4FQ4-IhOlY8sj-ZfVH4pdnmvAg0gVwruqXyfzWIpl8c3lxQaqzmz5Y_ff0f2SjiIm79NPZAv2DBZ8ErOuHW.jpg?quality=95&as=32x21,48x32,72x48,108x72,160x106,240x160,360x239,480x319,540x359,640x426,720x479,1080x718,1280x851,1440x958,2560x1703&from=bu&cs=2560x0"),
                        decision: .pending
                    )
                ],
                0
            )
        )
    }
}
