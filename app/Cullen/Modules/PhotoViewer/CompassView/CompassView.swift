//
//  CompassView.swift
//  Cullen
//

import SwiftUI
import Kingfisher

struct CompassView: View {

    @ObservedObject var viewModel: PhotoViewerViewModel
    let onSingleTap: () -> Void

    @State private var zoomScale: CGFloat = 1
    @StateObject private var zoomControl = ZoomControl()

    private enum Layout {
        static let doubleTapZoomScale: CGFloat = 3
    }

    var body: some View {
        let isZoomed = zoomScale > 1

        ZStack {
            imageContent(isZoomed: isZoomed)

            viewModel.compassViewModel.map {
                SwipeCompassView(viewModel: $0)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .gestureLayer(captures: { _ in !isZoomed }) {
            GestureTap(count: 1) { _ in
                onSingleTap()
            }

            GestureTap(count: 2) { location in
                zoomControl.zoom(to: Layout.doubleTapZoomScale, screenAnchor: location, animated: true)
            }

            GesturePan(
                filter: .any,
                onChanged: { translation in
                    viewModel.trackSwipe(translation: translation)
                },
                onEnded: { translation, velocity in
                    viewModel.endSwipe(translation: translation, velocity: velocity)
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

private extension CompassView {

    func imageContent(isZoomed: Bool) -> some View {
        ZStack {
            CullenImage(viewModel.currentPhoto.url)
                .resizable()
                .scaledToFit()
                .opacity(isZoomed ? 0 : 1)

            ZoomableImageView(
                viewModel: ZoomableImageViewModel(
                    url: viewModel.currentPhoto.url,
                    onZoomScaleChange: { scale in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            zoomScale = scale
                        }
                    }
                ),
                externalControl: zoomControl
            )
            .allowsHitTesting(isZoomed)
            .opacity(isZoomed ? 1 : 0)
        }
    }
}
