//
//  SortDirection.swift
//  Cullen
//

enum SortDirection {
    case ascending
    case descending

    mutating func toggle() {
        self = if self == .ascending {
            .descending
        } else {
            .ascending
        }
    }
}
