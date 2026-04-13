//
//  Decision.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//


enum Decision: String {
    case pending
    case approved
    case rejected
}

extension Decision: CaseIterable {}

extension Decision: Equatable {}

extension Decision: Codable {}
