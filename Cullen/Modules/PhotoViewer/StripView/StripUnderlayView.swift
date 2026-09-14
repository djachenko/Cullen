//
//  StripUnderlayView.swift
//  Cullen
//

import SwiftUI


struct StripUnderlayView: View {
    private enum Layout {
        static let iconSize: CGFloat = 24
        static let labelSize: CGFloat = 12
        static let spacing: CGFloat = 8
    }

    let decision: Decision

    var body: some View {
        ZStack {
            decision.color

            VStack(spacing: Layout.spacing) {
                Image(systemName: decision.icon)
                    .font(.system(size: Layout.iconSize, weight: .bold))

                Text(decision.label)
                    .font(.system(size: Layout.labelSize, weight: .semibold))
            }
            .foregroundStyle(.white)
        }
    }
}
