//
//  View+HorizontalDrag.swift
//  Cullen
//

import SwiftUI
import UIKit

extension View {
    func onHorizontalDrag(
        enabled: @escaping () -> Bool,
        onChanged: @escaping (CGFloat) -> Void,
        onEnded: @escaping (_ translation: CGFloat, _ velocity: CGFloat) -> Void
    ) -> some View {
        overlay(
            HorizontalPanGestureView(
                enabled: enabled,
                onChanged: onChanged,
                onEnded: onEnded
            )
        )
    }
}

// MARK: - HorizontalPanGestureView

private struct HorizontalPanGestureView: UIViewRepresentable {

    let enabled: () -> Bool
    let onChanged: (CGFloat) -> Void
    let onEnded: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isEnabled: enabled,
            onChanged: onChanged,
            onEnded: onEnded
        )
    }

    func makeUIView(context: Context) -> UIView {
        context.coordinator.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
        context.coordinator.isEnabled = enabled
    }
}

extension HorizontalPanGestureView {
    final class Coordinator: NSObject {
        var isEnabled: () -> Bool
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat, CGFloat) -> Void

        lazy var view = {
            let view = UIView()
            view.backgroundColor = .clear
            view.addGestureRecognizer(pan)

            return view
        }()

        private lazy var pan = {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(Coordinator.handlePan(_:)))
            pan.delegate = self

            return pan
        }()

        init(
            isEnabled: @escaping () -> Bool,
            onChanged: @escaping (CGFloat) -> Void,
            onEnded: @escaping (CGFloat, CGFloat) -> Void
        ) {
            self.isEnabled = isEnabled
            self.onChanged = onChanged
            self.onEnded = onEnded
        }
    }
}

extension HorizontalPanGestureView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isEnabled() else {
            return false
        }

        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              pan == self.pan else {
            return true
        }

        return pan.isHorizontal
    }
}

private extension HorizontalPanGestureView.Coordinator {
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view?.superview).x

        switch recognizer.state {
            case .changed:
                onChanged(translation)
            case .ended, .cancelled:
                let velocity = recognizer.velocity(in: recognizer.view?.superview).x

                onEnded(translation, velocity)
            default:
                break
        }
    }
}

// MARK: - UIPanGestureRecognizer

private extension UIPanGestureRecognizer {
    var isHorizontal: Bool {
        let velocity = velocity(in: view)
        return abs(velocity.x) > abs(velocity.y)
    }
}
