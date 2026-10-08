//
//  StatCardViewModel.swift
//  Cullen
//
//  Created by justin on 17/2/26.
//

import SwiftUI


struct StatCardViewModel {
    let title: String
    let value: String
    let icon: String
    let color: Color
}

extension StatCardViewModel {
    static func sets(title: String, value: String) -> Self {
        StatCardViewModel(
            title: title,
            value: value,
            icon: "folder.fill",
            color: Color(red: 0.3, green: 0.5, blue: 1.0)
        )
    }

    static func photos(title: String, value: String) -> Self {
        StatCardViewModel(
            title: title,
            value: value,
            icon: "photo.fill",
            color: Color(red: 0.9, green: 0.5, blue: 0.3)
        )
    }

    static func syncing(title: String, value: String) -> Self {
        StatCardViewModel(
            title: title,
            value: value,
            icon: "arrow.triangle.2.circlepath",
            color: Color(red: 0.5, green: 0.8, blue: 0.4)
        )
    }
}
