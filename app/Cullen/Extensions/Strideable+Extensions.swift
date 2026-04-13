//
//  Strideable+Extensions.swift
//  Cullen
//
//  Created by justin on 17/3/26.
//


extension Strideable where Stride: SignedInteger {
    func clamped(to range: Range<Self>) -> Self {
        guard !range.isEmpty else {
            return range.lowerBound
        }

        return clamped(to: range.lowerBound...range.upperBound.advanced(by: -1))
    }
}