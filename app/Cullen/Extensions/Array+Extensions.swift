//
//  Array+Extensions.swift
//  Cullen
//
//  Created by justin on 31/7/26.
//


extension Array {
    func forEach(_ body: (Element) async throws -> Void) async rethrows {
        for e in self {
            try await body(e)
        }
    }
}