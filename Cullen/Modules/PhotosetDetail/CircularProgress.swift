//
//  CircularProgress.swift
//  Cullen
//

import SwiftUI


struct CircularProgress: View {
    let value: Double
    let color: Color
    let lineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.25),
                    lineWidth: lineWidth
                )

            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
