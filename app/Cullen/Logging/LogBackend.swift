//
//  LogBackend.swift
//  Cullen
//

import Foundation

protocol LogBackend {
    func log(
        level: LogLevel,
        category: LogCategory,
        message: String
    )

    func export() async -> Data?
}
