//
//  Dictionary+Extensions.swift
//  Cullen
//
//  Created by justin on 31/3/26.
//


extension Dictionary {
    func contains(key: Key) -> Bool {
        self[key] != nil
    }
}