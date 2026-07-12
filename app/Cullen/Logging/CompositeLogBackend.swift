//
//  CompositeLogBackend.swift
//  Cullen
//
//  Fans a single log call out to several backends. Export delegates to the first backend
//  that produces a file.
//

import Foundation

final class CompositeLogBackend: LogBackend {

    private let backends: [LogBackend]

    init(backends: [LogBackend]) {
        self.backends = backends
    }

    func log(level: LogLevel, category: LogCategory, message: String) {
        backends.forEach {
            $0.log(level: level, category: category, message: message)
        }
    }

    func export() async -> Data? {
        for backend in backends {
            if let data = await backend.export() {
                return data
            }
        }

        return nil
    }
}
