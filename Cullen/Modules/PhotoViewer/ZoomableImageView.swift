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

    @available(*, deprecated, message: "Pan handled via gestureLayer since compass unification; internal pan recognizer is unused")
    var onPan: (_ recognizer: UIPanGestureRecognizer) -> Void = { _ in }
    var onZoomScaleChange: (CGFloat) -> Void = { _ in }
}

// MARK: - LayoutAwareScrollView

final class LayoutAwareScrollView: UIScrollView {
    var onLayout = {}

    override func layoutSubviews() {
        super.layoutSubviews()

        onLayout()
    }
}

// MARK: - ZoomableImageView

struct ZoomableImageView: UIViewRepresentable, GestureBlockerProvider {

    let viewModel: ZoomableImageViewModel
    let gestureBlockerLink = GestureRequirementLink()
    var externalControl: ZoomControl? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, link: gestureBlockerLink)
    }

    func makeUIView(context: Context) -> LayoutAwareScrollView {
        let scrollView = context.coordinator.scrollView
        scrollView.addSubview(context.coordinator.imageView)
        context.coordinator.loadImage(url: viewModel.url)
        externalControl?.connect(scrollView)
        return scrollView
    }

    func updateUIView(_ scrollView: LayoutAwareScrollView, context: Context) {
        if context.coordinator.currentURL != viewModel.url {
            context.coordinator.loadImage(url: viewModel.url)
            scrollView.setZoomScale(1, animated: false)
        }

        scrollView.maximumZoomScale = viewModel.maxZoomScale
        context.coordinator.viewModel = viewModel
        externalControl?.connect(scrollView)
    }
}

// MARK: - Coordinator

extension ZoomableImageView {

    final class Coordinator: NSObject {

        var viewModel: ZoomableImageViewModel
        var currentURL: URL?
        private let link: GestureRequirementLink

        private(set) lazy var scrollView: LayoutAwareScrollView = {
            let scrollView = LayoutAwareScrollView()
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = viewModel.maxZoomScale
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.bouncesZoom = true
            scrollView.clipsToBounds = false
            scrollView.backgroundColor = .clear
            scrollView.contentInsetAdjustmentBehavior = .never

            scrollView.addGestureRecognizer(doubleTap)

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

        private lazy var doubleTap: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(Coordinator.handleDoubleTap(_:))
            )
            recognizer.numberOfTapsRequired = 2
            link.recognizers = [recognizer]

            return recognizer
        }()

        @available(*, deprecated, message: "Pan handled via gestureLayer since compass unification; no longer wired to scrollView")
        private lazy var pan: UIPanGestureRecognizer = {
            let recognizer = UIPanGestureRecognizer(
                target: self,
                action: #selector(Coordinator.handlePan(_:))
            )
            recognizer.delegate = self

            return recognizer
        }()

        init(viewModel: ZoomableImageViewModel, link: GestureRequirementLink) {
            self.viewModel = viewModel
            self.link = link
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

            let insetV = max((scrollSize.height - contentSize.height) / 2, 0)
            let insetH = max((scrollSize.width  - contentSize.width)  / 2, 0)

            scrollView.contentInset = UIEdgeInsets(
                top: insetV, left: insetH, bottom: insetV, right: insetH
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

        @available(*, deprecated, message: "Pan handled via gestureLayer since compass unification")
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
