//
//  SwipeGestureHandler.swift
//  Cullen
//
//  Created by justin on 14/3/26.
//

import UIKit


struct SwipeGestureHandler {
    private enum Constants {
        static let deadZoneRadius = 10.0
        static let commitThreshold = 120.0
        static let velocityWeight = 0.3
    }

    // MARK: - Evaluate

    func evaluate(_ recognizer: UIPanGestureRecognizer) -> Double? {
        let translation = recognizer.translation(in: recognizer.view)
        let velocity = recognizer.velocity(in: recognizer.view)

        // Мёртвая зона — игнорируем случайные микро-свайпы
        let distance = translation.distance

        guard distance >= Constants.deadZoneRadius else {
            return nil
        }

        // Экстраполируем конечную точку с учётом velocity
        let projected = CGPoint(
            x: translation.x + velocity.x * Constants.velocityWeight,
            y: translation.y + velocity.y * Constants.velocityWeight
        )

        guard projected.distance >= Constants.commitThreshold else {
            return nil
        }

        let radiangle = atan2(projected.x, -projected.y)
        let degrees = (radiangle * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)

        return degrees
    }
}


