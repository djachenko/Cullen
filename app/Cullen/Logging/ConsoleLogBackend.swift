//
//  ConsoleLogBackend.swift
//  Cullen
//
//  Prints to stdout so logs are visible in the Xcode debug console when running attached.
//  Holds no state and does not support export.
//

import Foundation

final class ConsoleLogBackend: LogBackend {

    func log(level: LogLevel, category: LogCategory, message: String) {
        print("[\(category.rawValue)][\(level.marker)] \(message)")
    }

    func export() async -> Data? {
        nil
    }
}
