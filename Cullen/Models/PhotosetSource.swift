//
//  PhotosetSource.swift
//  Cullen
//
//  Created by justin on 21/3/26.
//


enum PhotosetSource {
    case vk
}

extension PhotosetSource {
    var keyStrategy: String {
        switch self {
            case .vk:
                return "index"
        }
    }
}
