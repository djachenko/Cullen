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

    private var presentation: DecisionPresentation {
        decision.presentation
    }

    var body: some View {
        ZStack {
            presentation.color

            VStack(spacing: Layout.spacing) {
                Image(systemName: presentation.icon)
                    .font(.system(size: Layout.iconSize, weight: .bold))

                Text(presentation.label)
                    .font(.system(size: Layout.labelSize, weight: .semibold))
            }
            .foregroundStyle(.white)
        }
    }
}
