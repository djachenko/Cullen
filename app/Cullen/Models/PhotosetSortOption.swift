//
//  PhotosetSortOption.swift
//  Cullen
//
//  Created by justin on 25/3/26.
//


enum PhotosetSortOption: String, CaseIterable, Identifiable {
    case recent = "Date"
    case name = "Name"
    case progress = "Progress"
    case photoCount = "Photos"
    case lastOpened = "Last Opened"

    static let `default`: Self = .lastOpened

    var id: String {
        rawValue
    }

    var defaultDirection: SortDirection {
        switch self {
            case .name:
                .ascending
            default:
                .descending
        }
    }
}
