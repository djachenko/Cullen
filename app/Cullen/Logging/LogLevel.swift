//
//  LogLevel.swift
//  Cullen
//

import OSLog

enum LogLevel {
    case debug
    case info
    case notice
    case error
    case fault

    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
}
