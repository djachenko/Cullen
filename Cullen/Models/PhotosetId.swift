//
//  PhotosetId.swift
//  Cullen
//
//  Created by justin on 25/3/26.
//

import Foundation


enum PhotosetId {
    case int(Int)
    case string(String)
    case uuid(UUID)
}

extension PhotosetId: Hashable {}

extension PhotosetId: CustomStringConvertible {
    var description: String {
        switch self {
        case .int(let id):
            "\(id)"
        case .string(let id):
            id
        case .uuid(let id):
            id.uuidString
        }
    }
}
