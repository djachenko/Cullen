//
//  GestureLayer.swift
//  Cullen
//

import SwiftUI
import UIKit

// MARK: - UIViewRepresentable

struct GestureLayer: UIViewRepresentable {

    let captures: (CGPoint) -> Bool
    let descriptors: [GestureDescriptor]

    func makeCoordinator() -> GestureLayerCoordinator {
        GestureLayerCoordinator()
    }

    func makeUIView(context: Context) -> GestureLayerView {
        let view = GestureLayerView()
        view.hitTestHandler = captures
        context.coordinator.install(on: view, descriptors: descriptors)
        return view
    }

    func updateUIView(_ view: GestureLayerView, context: Context) {
        view.hitTestHandler = captures
        context.coordinator.update(descriptors: descriptors)
    }
}

// MARK: - GestureBuilder

@resultBuilder
struct GestureBuilder {
    static func buildBlock(_ components: [GestureDescriptor]...) -> [GestureDescriptor] {
        components.flatMap { $0 }
    }

    static func buildArray(_ components: [[GestureDescriptor]]) -> [GestureDescriptor] {
        components.flatMap { $0 }
    }

    static func buildOptional(_ component: [GestureDescriptor]?) -> [GestureDescriptor] {
        component ?? []
    }

    static func buildEither(first component: [GestureDescriptor]) -> [GestureDescriptor] {
        component
    }

    static func buildEither(second component: [GestureDescriptor]) -> [GestureDescriptor] {
        component
    }

    static func buildExpression(_ expression: GestureDescriptor) -> [GestureDescriptor] {
        [expression]
    }
}

// MARK: - View modifier

extension View {
    func gestureLayer(
        captures: @escaping (CGPoint) -> Bool = { _ in true },
        @GestureBuilder _ gestures: () -> [GestureDescriptor]
    ) -> some View {
        overlay(
            GestureLayer(captures: captures, descriptors: gestures())
        )
    }
}
