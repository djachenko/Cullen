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

// TODO: Should color, icon and label be here???

extension SwipeDirection {
    static let up = SwipeDirection(
        label: "Next",
        icon: "arrow.up.circle.fill",
        color: .blue,
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

    static let down = SwipeDirection(
        label: "Prev",
        icon: "arrow.down.circle.fill",
        color: .orange,
        decision: nil,
        mainAngle: 180
    )

    static let left = SwipeDirection(
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
        let match = SwipeDirection.allDirections.min { direction in
            let delta = (angle - direction.mainAngle + 360).truncatingRemainder(dividingBy: 360)
            return min(delta, 360 - delta)
        }

        guard let match else {
            return nil
        }
        
        self = match
    }
}
