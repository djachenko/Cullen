//
//  Encodable+Extensions.swift
//  Cullen
//
//  Created by justin on 30/3/26.
//

import Foundation


extension Encodable {
    func toJson(at url: URL) throws {
        let data = try JSONEncoder().encode(self)

        try data.write(to: url, options: .atomic)
    }
}
