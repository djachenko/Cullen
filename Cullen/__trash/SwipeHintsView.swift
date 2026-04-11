//
//  SwipeHintsView.swift
//  Cullen
//
//  Created by justin on 5/3/26.
//

import SwiftUI


struct SwipeHintsView: View {
    @State private var isDragging: Bool = false

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 24) {
                swipeHintLabel("← Reject", color: .red)
                Spacer()
                swipeHintLabel("↑ Skip", color: .orange)
                Spacer()
                swipeHintLabel("Approve →", color: .green)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 100)
        }
        .opacity(isDragging ? 0 : 0.6)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }

    private func swipeHintLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Font.system(size: 12, weight: .medium))
            .foregroundColor(color)
    }
}
