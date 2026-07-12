//
//  URL+Identifiable.swift
//  Cullen
//
//  Enables presenting an exported log file via `.sheet(item:)`.
//

import Foundation

extension URL: @retroactive Identifiable {
    public var id: String {
        absoluteString
    }
}
