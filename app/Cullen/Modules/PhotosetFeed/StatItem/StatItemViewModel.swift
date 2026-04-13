//
//  StatItemViewModel.swift
//  Cullen
//
//  Created by justin on 15/2/26.
//

import SwiftUI


struct StatItemViewModel {
    let icon: String
    let value: Int
    let color: Color
}

extension StatItemViewModel {
    static func approved(count: Int) -> Self {
        StatItemViewModel(
            icon: "checkmark.circle.fill",
            value: count,
            color: Color.green
        )
    }

    static func rejected(count: Int) -> Self {
        StatItemViewModel(
            icon: "xmark.circle.fill",
            value: count,
            color: Color.red
        )
    }

    static func pending(count: Int) -> Self {
        StatItemViewModel(
            icon: "clock.fill",
            value: count,
            color: Color.orange
        )
    }
}
