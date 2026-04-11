//
//  SwipeDirection.swift
//  Cullen
//
//  Created by justin on 5/3/26.
//

import SwiftUI


enum SwipeDirection {
    case right  // Approve
    case left   // Reject
    case up     // Next
    case down   // Previous

    var decision: Decision? {
        switch self {
        case .right: return .approved
        case .left:  return .rejected
        case .up:    return nil
        case .down:  return nil
        }
    }

    var label: String {
        switch self {
        case .right: return "Approve"
        case .left:  return "Reject"
        case .up:    return "Next"
        case .down:  return "Prev"
        }
    }

    var icon: String {
        switch self {
        case .right: return "checkmark.circle.fill"
        case .left:  return "xmark.circle.fill"
        case .up:    return "arrow.up.circle.fill"
        case .down:  return "arrow.down.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .right: return .green
        case .left:  return .red
        case .up:    return .blue
        case .down:  return .orange
        }
    }
}
