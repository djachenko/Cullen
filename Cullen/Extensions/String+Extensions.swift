//
//  String+Extensions.swift
//  Cullen
//
//  Created by justin on 30/3/26.
//


extension String {
    func removing(suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }

        return String(dropLast(suffix.count))
    }
}
