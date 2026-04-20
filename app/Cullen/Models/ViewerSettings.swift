//
//  ViewerSettings.swift
//  Cullen
//

import Foundation


enum ViewerMode: String, CaseIterable, Codable {
    case compass
    case strip
//    case buttons

    var icon: String {
        switch self {
        case .compass:
            "safari"
        case .strip:
            "safari"
//            "rectangle.3.offgrid.portrait"
//        case .buttons:
//            "hand.tap"
        }
    }

    var title: String {
        switch self {
        case .compass:
            "Compass"
        case .strip:
            "Strip"
//        case .buttons:
//            "Buttons"
        }
    }
}

struct ViewerSettings: Codable, Equatable {
    var mode: ViewerMode

    static let `default` = ViewerSettings(mode: .compass)
}
