//
//  Comparable+Extensions.swift
//  Cullen
//
//  Created by justin on 17/3/26.
//


extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        if self < range.lowerBound {
            range.lowerBound
        } else if self > range.upperBound {
            range.upperBound
        } else {
            self
        }
    }
}
