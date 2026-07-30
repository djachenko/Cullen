//
//  Collection+Extensions.swift
//  Cullen
//
//  Created by justin on 22/3/26.
//


extension Collection {
    func min(by key: (Element) -> some Comparable) -> Element? {
        self.min { key($0) < key($1) }
    }

    func max(by key: (Element) -> some Comparable) -> Element? {
        self.max { key($0) < key($1) }
    }

    func sorted(by key: (Element) -> some Comparable, reverse: Bool = false) -> [Element] {
        if reverse {
            sorted { key($0) > key($1) }
        } else {
            sorted { key($0) < key($1) }
        }
    }
}
    