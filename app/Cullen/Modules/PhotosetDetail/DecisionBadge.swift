//
//  DecisionBadge.swift
//  Cullen
//
//  Created by justin on 27/3/26.
//

import SwiftUI


struct DecisionBadge: View {
    private let icon: String
    private let color: Color

    private init(icon: String, color: Color) {
        self.icon = icon
        self.color = color
    }

    var body: some View {
        Image(systemName: icon)
            .foregroundColor(color)
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}

extension DecisionBadge {
    static let approved = DecisionBadge(icon: "checkmark.circle.fill", color: .green)
    static let rejected = DecisionBadge(icon: "xmark.circle.fill", color: .red)
    static let pending = DecisionBadge(icon: "circle.dotted", color: .secondary)

    init(decision: Decision) {
        self = switch decision {
        case .approved:
                .approved
        case .rejected:
                .rejected
        case .pending:
                .pending
        }
    }

    func size(_ size: Double) -> some View {
        font(.system(size: size, weight: .semibold))
    }
}
