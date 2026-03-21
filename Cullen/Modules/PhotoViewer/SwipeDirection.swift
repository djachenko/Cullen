//
//  SwipeDirection.swift
//  Cullen
//
//  Created by justin on 5/3/26.
//

import SwiftUI


struct SwipeDirection: Hashable {
    let label: String
    let icon: String
    let color: Color
    let decision: Decision?
    let mainAngle: Double
}

extension SwipeDirection: Equatable {
    static func == (lhs: SwipeDirection, rhs: SwipeDirection) -> Bool {
        lhs.mainAngle == rhs.mainAngle
    }
}

extension SwipeDirection {
    static let up    = SwipeDirection(
        label: "Prev",
        icon: "arrow.up.circle.fill",
        color: .orange,
        decision: nil,
        mainAngle: 0
    )
    static let right = SwipeDirection(
        label: "Approve",
        icon: "checkmark.circle.fill",
        color: .green,
        decision: .approved,
        mainAngle: 90
    )
    static let down  = SwipeDirection(
        label: "Next",
        icon: "arrow.down.circle.fill",
        color: .blue,
        decision: nil,
        mainAngle: 180
    )
    static let left  = SwipeDirection(
        label: "Reject",
        icon: "xmark.circle.fill",
        color: .red,
        decision: .rejected,
        mainAngle: 270
    )
    
    static let allDirections: [SwipeDirection] = [
        .up,
        .right,
        .down,
        .left
    ]
}

extension SwipeDirection {
    init?(angle: Double) {
        let match = SwipeDirection.allDirections.min(by: { direction in
            let delta = (angle - direction.mainAngle + 360).truncatingRemainder(dividingBy: 360)
            return min(delta, 360 - delta)
        })

        guard let match else {
            return nil
        }
        
        self = match
    }
}

// MARK: - Collection+KeyPath (временно)

extension Collection {
    func min(by key: (Element) -> some Comparable) -> Element? {
        self.min(by: { key($0) < key($1) })
    }

    func max(by key: (Element) -> some Comparable) -> Element? {
        self.max(by: { key($0) < key($1) })
    }

    func sorted(by key: (Element) -> some Comparable) -> [Element] {
        self.sorted(by: { key($0) < key($1) })
    }
}
