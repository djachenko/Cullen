//
//  View+Tap.swift
//  Cullen

import SwiftUI
import UIKit

extension View {
    func onTap(_ action: @escaping () -> Void) -> TappableView<Self> {
        TappableView(
            content: self,
            action: action,
            blockingLink: (self as? GestureBlockerProvider)?.gestureBlockerLink
        )
    }
}

// MARK: - TappableView

struct TappableView<Content: View>: View, GestureBlockerProvider {

    let content: Content
    let action: () -> Void
    let blockingLink: GestureRequirementLink?
    let gestureBlockerLink = GestureRequirementLink()

    var body: some View {
        content.overlay(
            TapGestureView(
                action: action,
                blockingLink: blockingLink,
                ownLink: gestureBlockerLink
            )
        )
    }
}

// MARK: - TapGestureView

private struct TapGestureView: UIViewRepresentable {

    let action: () -> Void
    let blockingLink: GestureRequirementLink?
    let ownLink: GestureRequirementLink

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action, blockingLink: blockingLink, ownLink: ownLink)
    }

    func makeUIView(context: Context) -> UIView {
        context.coordinator.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }
}

// MARK: - Coordinator

extension TapGestureView {

    final class Coordinator: NSObject {

        var action: () -> Void

        lazy var view: UIView = {
            let view = UIView()
            view.backgroundColor = .clear
            view.addGestureRecognizer(recognizer)
            return view
        }()

        private lazy var recognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handle))
            recognizer.numberOfTapsRequired = 1

            blockingLink?.recognizers.forEach {
                recognizer.require(toFail: $0)
            }

            ownLink.recognizers = (blockingLink?.recognizers ?? []) + [recognizer]

            return recognizer
        }()

        private let blockingLink: GestureRequirementLink?
        private let ownLink: GestureRequirementLink

        init(action: @escaping () -> Void, blockingLink: GestureRequirementLink?, ownLink: GestureRequirementLink) {
            self.action = action
            self.blockingLink = blockingLink
            self.ownLink = ownLink
        }

        @objc private func handle() {
            action()
        }
    }
}

//extension TapGestureView.Coordinator: UIGestureRecognizerDelegate {
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        <#code#>
//    }
//}
