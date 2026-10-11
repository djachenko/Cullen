//
//  UInt+Extensions.swift
//  Cullen
//
//  Created by justin on 10/10/26.
//


extension UInt {
    static func gb(_ size: UInt) -> Self {
        return size * .mb(1024)
    }

    static func mb(_ size: UInt) -> Self {
        return size * .kb(1024)
    }

    static func kb(_ size: UInt) -> Self {
        return size * 1024
    }
}