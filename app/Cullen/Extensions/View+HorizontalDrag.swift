//
//  View+HorizontalDrag.swift
//  Cullen
//

import SwiftUI
import UIKit

extension View {
    func onHorizontalDrag(
        onChanged: @escaping (CGFloat) -> Void,
        onEnded: @escaping (_ translation: CGFloat, _ velocity: CGFloat) -> Void
    ) -> some View {
        overlay(
            HorizontalPanGestureView(onChanged: onChanged, onEnded: onEnded)
        )
    }
}

// MARK: - HorizontalPanGestureView

private struct HorizontalPanGestureView: UIViewRepresentable {

    let onChanged: (CGFloat) -> Void
    let onEnded: (_ translation: CGFloat, _ velocity: CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }
}

extension HorizontalPanGestureView {
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat, CGFloat) -> Void

        init(onChanged: @escaping (CGFloat) -> Void, onEnded: @escaping (CGFloat, CGFloat) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

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

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
                return true
            }

            return pan.isHorizontal
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
