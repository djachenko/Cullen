//
//  SwipeCompassView.swift
//  Cullen
//
//  Presentation Layer - Swipe Direction Compass
//

import SwiftUI

// MARK: - SwipeCompassSector

private struct SwipeCompassSector {
    let direction: SwipeDirection
    let centerAngle: Angle
}


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

    private static let sectors = SwipeDirection.allDirections.map { direction in
        // mainAngle: 0° наверху, по часовой
        // CoreGraphics: 0° справа, по часовой → сдвиг на -90°
        SwipeCompassSector(
            direction: direction,
            centerAngle: direction.mainAngleDegrees - .pi / 2
        )
    }


    var body: some View {
        ZStack {
            Color.black
                .opacity(0.3 * viewModel.progress)
                .ignoresSafeArea()

            ZStack {
                ForEach(SwipeCompassView.sectors, id: \.direction.label) { sector in
                    sectorView(sector: sector)
                }
            }
            .frame(width: Layout.diameter, height: Layout.diameter)
            .scaleEffect(0.5 + 0.5 * viewModel.progress)
            .opacity(Double(viewModel.progress))
        }
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: viewModel.progress)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: viewModel.activeDirection.label)
    }
}

private extension SwipeCompassView {
    private static let spanAngle = Angle.radians(2 * .pi) / Double(sectors.count)

    func sectorView(sector: SwipeCompassSector) -> some View {
        let isActive = viewModel.activeDirection.label == sector.direction.label

        return ZStack {
            RingSectorShape(
                centerAngle: sector.centerAngle,
                spanAngle: SwipeCompassView.spanAngle,
                innerRadius: Layout.innerRadius,
                outerRadius: Layout.outerRadius,
                gapPixels: Layout.gapPixels
            )
            .fill(sector.direction.color.opacity(isActive ? 0.8 : 0.25))
            .overlay(
                RingSectorShape(
                    centerAngle: sector.centerAngle,
                    spanAngle: SwipeCompassView.spanAngle,
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

    func iconLabel(sector: SwipeCompassSector, isActive: Bool) -> some View {
        let r = Layout.midRadius
        let x = Layout.outerRadius + cos(sector.centerAngle.radians) * r
        let y = Layout.outerRadius + sin(sector.centerAngle.radians) * r

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
