//
//  Collection+Extensions.swift
//  Cullen
//
//  Created by justin on 22/3/26.
//


extension Collection {
    func min(by key: (Element) -> some Comparable) -> Element? {
        self.min(by: { key($0) < key($1) })
    }

    func max(by key: (Element) -> some Comparable) -> Element? {
        self.max(by: { key($0) < key($1) })
    }

    func sorted(by key: (Element) -> some Comparable) -> [Element] {
        self.sorted(by: { key($0) < key($1) })
    }
}