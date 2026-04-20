//
//  DecisionBadge.swift
//  Cullen
//

import SwiftUI


struct DecisionBadge: View {
    private let icon: String
    private let color: Color

    init(icon: String, color: Color) {
        self.icon = icon
        self.color = color
    }

    var body: some View {
        Image(systemName: icon)
            .foregroundColor(color)
            .shadow(
                color: .white.opacity(0.4),
                radius: 2,
                x: 0,
                y: 1
            )
    }

    func size(_ size: Double) -> some View {
        font(.system(size: size, weight: .semibold))
    }
}

extension DecisionBadge {
    init(decision: Decision) {
        self.init(icon: decision.icon, color: decision.color)
    }
}
