//
//  ZoomableImageView.swift
//  Cullen
//
//  Presentation Layer - Zoomable Photo View
//

import SwiftUI
import UIKit
import Kingfisher

// MARK: - ZoomableImageViewModel

struct ZoomableImageViewModel {
    let url: URL?
    var maxZoomScale: CGFloat = 5
    var doubleTapZoomScale: CGFloat = 3
    var panRequiresHorizontal: Bool = false
    var bouncesZoom: Bool = true
    var onSingleTap: () -> Void = {}
    var onPan: (_ recognizer: UIPanGestureRecognizer) -> Void = { _ in }
    var onZoomScaleChange: (CGFloat) -> Void = { _ in }
    var onAspectRatioChange: (CGFloat) -> Void = { _ in }
}

// MARK: - LayoutAwareScrollView

final class LayoutAwareScrollView: UIScrollView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}

// MARK: - ZoomableImageView

struct ZoomableImageView: UIViewRepresentable {

    let viewModel: ZoomableImageViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> LayoutAwareScrollView {
        let scrollView = context.coordinator.scrollView
        scrollView.addSubview(context.coordinator.imageView)
        context.coordinator.loadImage(url: viewModel.url)
        return scrollView
    }

    func updateUIView(_ scrollView: LayoutAwareScrollView, context: Context) {
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

        private(set) lazy var scrollView: LayoutAwareScrollView = {
            let scrollView = LayoutAwareScrollView()
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = viewModel.maxZoomScale
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.bouncesZoom = viewModel.bouncesZoom
            scrollView.clipsToBounds = false
            scrollView.backgroundColor = .clear
            scrollView.contentInsetAdjustmentBehavior = .never

            scrollView.addGestureRecognizer(singleTap)
            scrollView.addGestureRecognizer(doubleTap)
            scrollView.addGestureRecognizer(pan)

            scrollView.onLayout = { [weak self] in
                self?.layoutImageView()
            }

            return scrollView
        }()

        let imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            return imageView
        }()

        private lazy var singleTap: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(Coordinator.handleSingleTap)
            )
            recognizer.numberOfTapsRequired = 1
            recognizer.require(toFail: doubleTap)
            return recognizer
        }()

        private lazy var doubleTap: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(Coordinator.handleDoubleTap(_:))
            )
            recognizer.numberOfTapsRequired = 2
            return recognizer
        }()

        private lazy var pan: UIPanGestureRecognizer = {
            let recognizer = UIPanGestureRecognizer(
                target: self,
                action: #selector(Coordinator.handlePan(_:))
            )
            recognizer.delegate = self
            return recognizer
        }()

        init(viewModel: ZoomableImageViewModel) {
            self.viewModel = viewModel
        }

        // MARK: - Image Loading

        @MainActor
        func loadImage(url: URL?) {
            currentURL = url
            imageView.image = nil

            guard let url else {
                return
            }

            imageView.setCullenImage(with: url) { [weak self] in
                self?.layoutImageView()

                if let image = self?.imageView.image, image.size.height > 0 {
                    self?.viewModel.onAspectRatioChange(image.size.width / image.size.height)
                }
            }
        }

        // MARK: - Layout

        func layoutImageView() {
            guard scrollView.zoomScale == 1 else {
                return
            }

            guard let image = imageView.image else {
                return
            }

            let scrollSize = scrollView.bounds.size

            guard scrollSize.width > 0, scrollSize.height > 0 else {
                return
            }

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
        viewModel.onZoomScaleChange(scrollView.zoomScale)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        viewModel.onZoomScaleChange(scale)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ZoomableImageView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard scrollView.zoomScale == 1 else {
            return false
        }
        guard viewModel.panRequiresHorizontal else {
            return true
        }
        let velocity = pan.velocity(in: scrollView)
        return abs(velocity.x) > abs(velocity.y)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
