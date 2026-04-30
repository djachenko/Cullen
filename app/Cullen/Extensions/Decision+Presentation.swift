//
//  Decision+Presentation.swift
//  Cullen
//

import SwiftUI


extension Decision {
    var icon: String {
        switch self {
        case .approved:
            "checkmark.circle.fill"
        case .rejected:
            "xmark.circle.fill"
        case .pending:
            "circle.dotted"
        }
    }

    var color: Color {
        switch self {
        case .approved:
            .green
        case .rejected:
            .red
        case .pending:
            .secondary
        }
    }

    var label: String {
        switch self {
        case .approved:
            "Approve"
        case .rejected:
            "Reject"
        case .pending:
            ""
        }
    }
}
