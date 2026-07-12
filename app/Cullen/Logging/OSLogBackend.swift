//
//  OSLogBackend.swift
//  Cullen
//
//  Emits through os.Logger (readable in Console.app when tethered) and keeps a bounded
//  in-memory buffer of every line for on-device export — debug/info levels are not persisted
//  by the unified logging store, so OSLogStore alone can't reconstruct them.
//

import Foundation
import OSLog

final class OSLogBackend: LogBackend {

    private enum Limits {
        static let bufferCapacity = 10_000
    }

    private let subsystem = Bundle.main.bundleIdentifier ?? "Cullen"
    private var loggers: [LogCategory: os.Logger] = [:]
    private var buffer: [String] = []
    private let lock = NSLock()

    func log(level: LogLevel, category: LogCategory, message: String) {
        logger(for: category).log(level: level.osLogType, "\(message, privacy: .public)")

        append("\(Date().formatted(.iso8601)) [\(category.rawValue)] \(message)")
    }

    func export() async -> Data? {
        let contents = snapshot().joined(separator: "\n")

        guard !contents.isEmpty else {
            return nil
        }

        let data = Data(contents.utf8)

        logger(for: .app).log(level: .info, "export: \(data.count) bytes, \(snapshot().count) lines")

        return data
    }

    private func append(_ line: String) {
        lock.lock()
        defer { lock.unlock() }

        buffer.append(line)

        if buffer.count > Limits.bufferCapacity {
            buffer.removeFirst(buffer.count - Limits.bufferCapacity)
        }
    }

    private func snapshot() -> [String] {
        lock.lock()
        defer { lock.unlock() }

        return buffer
    }

    private func logger(for category: LogCategory) -> os.Logger {
        lock.lock()
        defer { lock.unlock() }

        if let existing = loggers[category] {
            return existing
        }

        let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = logger

        return logger
    }
}
