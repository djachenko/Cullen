//
//  SwipeGestureHandler.swift
//  Cullen
//
//  Created by justin on 14/3/26.
//

import UIKit


struct SwipeGestureHandler {

    // MARK: - Configuration

    /// Минимальное расстояние от старта до точки где начинаем считать направление
    var deadZoneRadius: CGFloat = 10
    /// Минимальная экстраполированная дистанция для засчитывания свайпа
    var commitThreshold: CGFloat = 120
    /// Насколько velocity влияет на экстраполяцию
    var velocityWeight: CGFloat = 0.3

    // MARK: - Evaluate

    /// Возвращает направление свайпа или nil если жест не дотянул до порога.
    /// Вызывать только когда recognizer.state == .ended
    func evaluate(_ recognizer: UIPanGestureRecognizer) -> SwipeDirection? {
        let translation = recognizer.translation(in: recognizer.view)
        let velocity = recognizer.velocity(in: recognizer.view)

        // Мёртвая зона — игнорируем случайные микро-свайпы
        let distance = sqrt(translation.x * translation.x + translation.y * translation.y)
        guard distance >= deadZoneRadius else { return nil }

        // Экстраполируем конечную точку с учётом velocity
        let projected = CGPoint(
            x: translation.x + velocity.x * velocityWeight,
            y: translation.y + velocity.y * velocityWeight
        )

        // Определяем доминирующую ось
        let dominantDistance: CGFloat
        let direction: SwipeDirection

        if abs(projected.x) > abs(projected.y) {
            dominantDistance = abs(projected.x)
            direction = projected.x > 0 ? .right : .left
        } else {
            dominantDistance = abs(projected.y)
            direction = projected.y > 0 ? .down : .up
        }

        return dominantDistance >= commitThreshold ? direction : nil
    }
}
