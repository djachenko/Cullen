//
//  CGRect+Extensions.swift
//  Cullen
//
//  Created by justin on 27/3/26.
//

import CoreGraphics


extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
