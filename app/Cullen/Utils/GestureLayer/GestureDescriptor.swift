//
//  GestureDescriptor.swift
//  Cullen
//

import UIKit

// MARK: - Protocol

protocol GestureDescriptor {}

// MARK: - GestureTap

struct GestureTap: GestureDescriptor {
    var count: Int
    var when: () -> Bool
    var action: (CGPoint) -> Void

    init(
        count: Int = 1,
        when: @escaping () -> Bool = { true },
        action: @escaping (CGPoint) -> Void
    ) {
        self.count = count
        self.when = when
        self.action = action
    }
}

// MARK: - GesturePan

enum PanFilter {
    case horizontal
    case vertical
    case any
}

struct GesturePan: GestureDescriptor {
    var filter: PanFilter
    var when: () -> Bool
    var onChanged: (CGPoint) -> Void
    var onEnded: (CGPoint, CGPoint) -> Void

    init(
        filter: PanFilter = .any,
        when: @escaping () -> Bool = { true },
        onChanged: @escaping (CGPoint) -> Void = { _ in },
        onEnded: @escaping (CGPoint, CGPoint) -> Void = { _, _ in }
    ) {
        self.filter = filter
        self.when = when
        self.onChanged = onChanged
        self.onEnded = onEnded
    }
}

// MARK: - GesturePinch

struct GesturePinch: GestureDescriptor {
    var when: () -> Bool
    var onChanged: (CGFloat, CGPoint) -> Void

    init(
        when: @escaping () -> Bool = { true },
        onChanged: @escaping (CGFloat, CGPoint) -> Void = { _, _ in }
    ) {
        self.when = when
        self.onChanged = onChanged
    }
}
