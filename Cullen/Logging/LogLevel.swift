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

    var marker: String {
        switch self {
        case .debug:   "DBG"
        case .info:    "INF"
        case .notice:  "NTC"
        case .error:   "ERR"
        case .fault:   "FLT"
        }
    }

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
