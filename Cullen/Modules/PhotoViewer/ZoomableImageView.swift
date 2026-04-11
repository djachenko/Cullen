//
//  ZoomableImageView.swift
//  Cullen
//
//  Presentation Layer - Zoomable Photo View
//

import SwiftUI
import UIKit

// MARK: - ZoomableImageViewModel

struct ZoomableImageViewModel {
    let url: URL?
    var maxZoomScale: CGFloat = 5
    var doubleTapZoomScale: CGFloat = 3
    var onSingleTap: () -> Void = {}
    var onPan: (_ recognizer: UIPanGestureRecognizer) -> Void = { _ in }
}

// MARK: - ZoomableImageView

struct ZoomableImageView: UIViewRepresentable {

    let viewModel: ZoomableImageViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = context.coordinator.scrollView
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = viewModel.maxZoomScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never

        let imageView = context.coordinator.imageView
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSingleTap)
        )
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        scrollView.addGestureRecognizer(pan)

        context.coordinator.loadImage(url: viewModel.url)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if context.coordinator.currentURL != viewModel.url {
            context.coordinator.loadImage(url: viewModel.url)
            scrollView.setZoomScale(1, animated: false)
        }
        scrollView.maximumZoomScale = viewModel.maxZoomScale
        context.coordinator.viewModel = viewModel
    }
}

// MARK: - Coordinator

extension ZoomableImageView {

    final class Coordinator: NSObject {

        var viewModel: ZoomableImageViewModel
        var currentURL: URL?

        let scrollView = UIScrollView()
        let imageView = UIImageView()

        init(viewModel: ZoomableImageViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - Image Loading

        func loadImage(url: URL?) {
            currentURL = url
            imageView.image = nil

            guard let url else { return }

            Task {
                guard
                    let (data, _) = try? await URLSession.shared.data(from: url),
                    let image = UIImage(data: data)
                else { return }

                await MainActor.run {
                    self.imageView.image = image
                    self.layoutImageView()
                }
            }
        }

        // MARK: - Layout

        func layoutImageView() {
            guard let image = imageView.image else { return }
            let scrollSize = scrollView.bounds.size
            guard scrollSize.width > 0, scrollSize.height > 0 else { return }

            let scale = min(
                scrollSize.width / image.size.width,
                scrollSize.height / image.size.height
            )
            let fittedSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )

            imageView.frame = CGRect(origin: .zero, size: fittedSize)
            scrollView.contentSize = fittedSize
            centerImageView()
        }

        func centerImageView() {
            let scrollSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize
            scrollView.contentInset = UIEdgeInsets(
                top: max((scrollSize.height - contentSize.height) / 2, 0),
                left: max((scrollSize.width - contentSize.width) / 2, 0),
                bottom: max((scrollSize.height - contentSize.height) / 2, 0),
                right: max((scrollSize.width - contentSize.width) / 2, 0)
            )
        }

        // MARK: - Gesture Handlers

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            if scrollView.zoomScale > 1 {
                scrollView.setZoomScale(1, animated: true)
            } else {
                let location = recognizer.location(in: imageView)
                let scale = viewModel.doubleTapZoomScale
                let size = CGSize(
                    width: scrollView.bounds.width / scale,
                    height: scrollView.bounds.height / scale
                )
                let origin = CGPoint(
                    x: location.x - size.width / 2,
                    y: location.y - size.height / 2
                )
                scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
            }
        }

        @objc func handleSingleTap() {
            viewModel.onSingleTap()
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            viewModel.onPan(recognizer)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomableImageView.Coordinator: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ZoomableImageView.Coordinator: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        scrollView.zoomScale == 1
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
