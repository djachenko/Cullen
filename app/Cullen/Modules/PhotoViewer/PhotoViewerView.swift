//
//  PhotoViewerView.swift
//  Cullen
//
//  Created by justin on 22/2/26.
//

import SwiftUI
import PopGestureRecognizerSwiftUI

// MARK: - PhotoViewerView

struct PhotoViewerView: View {

    // MARK: - Constants

    private enum Layout {
        static let maxZoomScale: CGFloat = 5
        static let doubleTapZoomScale: CGFloat = 3
    }

    // MARK: - Properties

    @ObservedObject var viewModel: PhotoViewerViewModel

    @State private var isUIVisible = true

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            modeView
        }
        .navigationBarHidden(!isUIVisible)
        .navigationTitle("\(viewModel.currentIndex + 1) / \(viewModel.totalCount)")
        .navigationBarTitleDisplayMode(.inline)
        .statusBarHidden(!isUIVisible)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    modeSwitchButton
                    decisionBadge
                }
            }
        }
        .swipeBackGestureDisabled()
        .animation(.easeInOut(duration: 0.2), value: isUIVisible)
        .task {
            await viewModel.loadDecisions()
        }
    }
}

private extension PhotoViewerView {
    @ViewBuilder
    var modeView: some View {
        switch viewModel.settings.mode {
            case .compass:
                compassView
            case .strip:
                stripView
        }
    }

    var compassView: some View {
        ZStack {
            ZoomableImageView(
                viewModel: ZoomableImageViewModel(
                    url: viewModel.currentPhoto.url,
                    maxZoomScale: Layout.maxZoomScale,
                    doubleTapZoomScale: Layout.doubleTapZoomScale,
//                    onSingleTap: {
//                        isUIVisible.toggle()
//                    },
                    onPan: viewModel.handle(recognizer:)
                )
            )
            .onTap {
                isUIVisible.toggle()
            }
            .ignoresSafeArea()
            .id(viewModel.currentIndex)
            .transition(.opacity)

            viewModel.compassViewModel.map {
                SwipeCompassView(viewModel: $0)
                    .allowsHitTesting(false)
            }
        }
    }

    var stripView: some View {
        StripV5View(viewModel: viewModel)
    }
}

// MARK: Toolbar

extension PhotoViewerView {
    var modeSwitchButton: some View {
        Button {
            viewModel.cycleViewerMode()
        } label: {
            Image(systemName: viewModel.settings.mode.icon)
        }
    }

    var decisionBadge: some View {
        Button {
            viewModel.resetDecision()
        } label: {
            DecisionBadge(decision: viewModel.decisions[viewModel.currentPhoto.id] ?? .pending)
        }
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        Cullen.resolver ~> (
            PhotoViewerView.self,
            with:
                [
                    Photo(
                        id: "test",
                        url: URL(string: "https://sun9-38.userapi.com/s/v1/ig2/cMnRR4FQ4-IhOlY8sj-ZfVH4pdnmvAg0gVwruqXyfzWIpl8c3lxQaqzmz5Y_ff0f2SjiIm79NPZAv2DBZ8ErOuHW.jpg?quality=95&as=32x21,48x32,72x48,108x72,160x106,240x160,360x239,480x319,540x359,640x426,720x479,1080x718,1280x851,1440x958,2560x1703&from=bu&cs=2560x0")!,
                    )
                ],
            0,
            PhotosetId.int(0)
        )
    }
}
