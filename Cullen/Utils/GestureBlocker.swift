//
//  GestureBlocker.swift
//  Cullen

import UIKit

final class GestureRequirementLink {
    var recognizers: [UIGestureRecognizer] = []
}

protocol GestureBlockerProvider {
    var gestureBlockerLink: GestureRequirementLink { get }
}
