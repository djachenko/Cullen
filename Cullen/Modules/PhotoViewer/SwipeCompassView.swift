//
//  SwipeCompassView.swift
//  Cullen
//
//  Presentation Layer - Swipe Direction Compass
//

import SwiftUI

// MARK: - SwipeCompassSector

struct SwipeCompassSector {
    let direction: SwipeDirection
    let centerAngle: Double
}

// MARK: - RingSectorShape

private struct RingSectorShape: Shape {

    let centerAngle: Double
    let spanAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    /// Физический зазор в пикселях — одинаковый по всей высоте сектора
    let gapPixels: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Угловой зазор разный для внешней и внутренней дуги —
        // чтобы физическое расстояние между секторами было одинаковым везде.
        // asin(halfGap / r) даёт угол от центра до края зазора.
        let halfGap = gapPixels / 2
        let outerGap = 2 * asin(Double(halfGap / outerRadius))
        let innerGap = 2 * asin(Double(halfGap / innerRadius))

        let outerStart = centerAngle - spanAngle / 2 + outerGap / 2
        let outerEnd   = centerAngle + spanAngle / 2 - outerGap / 2
        let innerStart = centerAngle - spanAngle / 2 + innerGap / 2
        let innerEnd   = centerAngle + spanAngle / 2 - innerGap / 2

        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: .radians(outerStart),
            endAngle: .radians(outerEnd),
            clockwise: false
        )
        // Линия от конца внешней дуги к концу внутренней
        let innerEndPoint = CGPoint(
            x: center.x + innerRadius * CGFloat(cos(innerEnd)),
            y: center.y + innerRadius * CGFloat(sin(innerEnd))
        )
        path.addLine(to: innerEndPoint)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: .radians(innerEnd),
            endAngle: .radians(innerStart),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - SwipeCompassView

struct SwipeCompassViewModel {
    let activeDirection: SwipeDirection
    let progress: CGFloat
}

struct SwipeCompassView: View {

    private enum Layout {
        static let outerRadius: CGFloat = 140
        static let innerRadius: CGFloat = 75
        static let gapPixels:   CGFloat = 4
        static var diameter:    CGFloat { outerRadius * 2 }
        static var midRadius:   CGFloat { (outerRadius + innerRadius) / 2 }
    }

    let viewModel: SwipeCompassViewModel

    private var sectors: [SwipeCompassSector] {
        SwipeDirection.allDirections.map { direction in
            // mainAngle: 0° наверху, по часовой
            // CoreGraphics: 0° справа, по часовой → сдвиг на -90°
            let centerAngle = (direction.mainAngle - 90) * .pi / 180
            return SwipeCompassSector(direction: direction, centerAngle: centerAngle)
        }
    }

    private var spanAngle: Double {
        2 * Double.pi / Double(sectors.count)
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.3 * viewModel.progress)
                .ignoresSafeArea()

            ZStack {
                ForEach(sectors, id: \.direction.label) { sector in
                    sectorView(sector)
                }
            }
            .frame(width: Layout.diameter, height: Layout.diameter)
            .scaleEffect(0.5 + 0.5 * viewModel.progress)
            .opacity(Double(viewModel.progress))
        }
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: viewModel.progress)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: viewModel.activeDirection.label)
    }

    private func sectorView(_ sector: SwipeCompassSector) -> some View {
        let isActive = viewModel.activeDirection.label == sector.direction.label

        return ZStack {
            RingSectorShape(
                centerAngle: sector.centerAngle,
                spanAngle: spanAngle,
                innerRadius: Layout.innerRadius,
                outerRadius: Layout.outerRadius,
                gapPixels: Layout.gapPixels
            )
            .fill(sector.direction.color.opacity(isActive ? 0.8 : 0.25))
            .overlay(
                RingSectorShape(
                    centerAngle: sector.centerAngle,
                    spanAngle: spanAngle,
                    innerRadius: Layout.innerRadius,
                    outerRadius: Layout.outerRadius,
                    gapPixels: Layout.gapPixels
                )
                .stroke(
                    sector.direction.color.opacity(isActive ? 1.0 : 0.3),
                    lineWidth: isActive ? 1.5 : 0.5
                )
            )
            .scaleEffect(isActive ? 1.05 : 1.0)

            iconLabel(sector: sector, isActive: isActive)
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActive)
        .frame(width: Layout.diameter, height: Layout.diameter)
    }

    private func iconLabel(sector: SwipeCompassSector, isActive: Bool) -> some View {
        let r = Layout.midRadius
        let x = Layout.outerRadius + CGFloat(cos(sector.centerAngle)) * r
        let y = Layout.outerRadius + CGFloat(sin(sector.centerAngle)) * r

        return VStack(spacing: 3) {
            Image(systemName: sector.direction.icon)
                .font(.system(size: isActive ? 18 : 14, weight: .bold))
            Text(sector.direction.label)
                .font(.system(size: isActive ? 11 : 9, weight: .semibold))
        }
        .foregroundColor(isActive ? .white : sector.direction.color.opacity(0.6))
        .shadow(color: .black.opacity(0.4), radius: 3)
        .position(x: x, y: y)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 48) {
            SwipeCompassView(viewModel: SwipeCompassViewModel(
                activeDirection: .right,
                progress: 0.9
            ))
            SwipeCompassView(viewModel: SwipeCompassViewModel(
                activeDirection: .up,
                progress: 0.6
            ))
            SwipeCompassView(viewModel: SwipeCompassViewModel(
                activeDirection: .down,
                progress: 0.3
            ))
        }
    }
}
