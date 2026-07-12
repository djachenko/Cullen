//
//  Logger.swift
//  Cullen
//
//  Application-facing logger. Category is bound at injection time; the backend is injected,
//  so the underlying implementation stays swappable. Consumers receive a `Logger` via DI
//  and never touch the backend directly.
//

protocol Logger {
    func debug(_ message: @autoclosure () -> String)
    func info(_ message: @autoclosure () -> String)
    func notice(_ message: @autoclosure () -> String)
    func error(_ message: @autoclosure () -> String)
    func fault(_ message: @autoclosure () -> String)
}

final class LoggerImpl: Logger {

    private let category: LogCategory
    private let backend: LogBackend

    init(category: LogCategory, backend: LogBackend) {
        self.category = category
        self.backend = backend
    }

    func debug(_ message: @autoclosure () -> String) {
        backend.log(level: .debug, category: category, message: message())
    }

    func info(_ message: @autoclosure () -> String) {
        backend.log(level: .info, category: category, message: message())
    }

    func notice(_ message: @autoclosure () -> String) {
        backend.log(level: .notice, category: category, message: message())
    }

    func error(_ message: @autoclosure () -> String) {
        backend.log(level: .error, category: category, message: message())
    }

    func fault(_ message: @autoclosure () -> String) {
        backend.log(level: .fault, category: category, message: message())
    }
}
