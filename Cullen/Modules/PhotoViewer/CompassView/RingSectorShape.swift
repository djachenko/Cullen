//
//  RingSectorShape.swift
//  Cullen
//
//  Created by justin on 27/3/26.
//

import SwiftUI


struct RingSectorShape: Shape {
    let centerAngle: Angle
    let spanAngle: Angle

    let innerRadius: Double
    let outerRadius: Double

    /// Физический зазор в пикселях — одинаковый по всей высоте сектора
    let gapPixels: Double

    func path(in rect: CGRect) -> Path {
        let center = rect.center

        // Угловой зазор разный для внешней и внутренней дуги —
        // чтобы физическое расстояние между секторами было одинаковым везде.
        // asin(halfGap / r) даёт угол от центра до края зазора.
        let halfGap = gapPixels / 2
        let outerGapRadians = Angle(radians: 2 * asin(Double(halfGap / outerRadius)))
        let innerGapRadians = Angle(radians: 2 * asin(Double(halfGap / innerRadius)))

        let outerAngle = spanAngle - outerGapRadians
        let innerAngle = spanAngle - innerGapRadians

        let outerStart = centerAngle - outerAngle / 2
        let outerEnd   = centerAngle + outerAngle / 2
        let innerStart = centerAngle - innerAngle / 2
        let innerEnd   = centerAngle + innerAngle / 2

        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: outerStart,
            endAngle: outerEnd,
            clockwise: false
        )
        // Линия от конца внешней дуги к концу внутренней
        let innerEndPoint = CGPoint(
            x: center.x + innerRadius * cos(innerEnd.radians),
            y: center.y + innerRadius * sin(innerEnd.radians)
        )
        path.addLine(to: innerEndPoint)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: innerEnd,
            endAngle: innerStart,
            clockwise: true
        )
        path.closeSubpath()

        return path
    }
}
