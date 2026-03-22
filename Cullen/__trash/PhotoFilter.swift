////
////  PhotoFilter.swift
////  Cullen
////
////  Created by justin on 14/3/26.
////
//
//
//enum PhotoFilter: String, CaseIterable {
//    case approved = "Approved"
//    case rejected = "Rejected"
//    case pending  = "Pending"
//
////    var id: String { rawValue }
//
////    var icon: String {
////        switch self {
////        case .approved: return "checkmark.circle.fill"
////        case .rejected: return "xmark.circle.fill"
////        case .pending:  return "clock.fill"
////        }
////    }
////
////    var color: Color {
////        switch self {
////        case .approved: return .green
////        case .rejected: return .red
////        case .pending:  return .orange
////        }
////    }
//
//    func matches(decision: Decision) -> Bool {
//        switch self {
//        case .approved: return decision == .approved
//        case .rejected: return decision == .rejected
//        case .pending:  return decision == .pending
//        }
//    }
//}
