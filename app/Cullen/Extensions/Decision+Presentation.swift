//
//  Decision+Presentation.swift
//  Cullen
//

import SwiftUI


struct DecisionPresentation {
    let icon: String
    let color: Color
    let title: String
    let label: String
}

extension DecisionPresentation {
    static let approved = DecisionPresentation(
        icon: "checkmark.circle.fill",
        color: .green,
        title: "Approved",
        label: "Approve"
    )

    static let rejected = DecisionPresentation(
        icon: "xmark.circle.fill",
        color: .red,
        title: "Rejected",
        label: "Reject"
    )

    static let pending = DecisionPresentation(
        icon: "circle.dotted",
        color: .secondary,
        title: "Pending",
        label: ""
    )
}

extension Decision {
    var presentation: DecisionPresentation {
        switch self {
        case .approved:
            .approved
        case .rejected:
            .rejected
        case .pending:
            .pending
        }
    }
}
