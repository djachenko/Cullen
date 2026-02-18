//
//  Decision.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//


enum Decision: String, Codable {
    case pending
    case approved
    case rejected
    
    var remoteFolderName: String {
        switch self {
        case .pending: 
            ""
        case .approved:
            "approved"
        case .rejected:
            "rejected"
        }
    }
}
