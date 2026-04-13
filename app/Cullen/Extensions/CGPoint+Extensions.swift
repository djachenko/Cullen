//
//  CGPoint+Extensions.swift
//  Cullen
//
//  Created by justin on 17/3/26.
//

import CoreGraphics


extension CGPoint {
    var distance: Double {
        sqrt(pow(x, 2) + pow(y, 2))
    }
}
