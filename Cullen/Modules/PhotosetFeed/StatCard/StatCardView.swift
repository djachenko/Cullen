//
//  StatCardView.swift
//  Cullen
//
//  Created by justin on 15/2/26.
//

import SwiftUI


struct StatCardView: View {
    let viewModel: StatCardViewModel

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(viewModel.color)

            Text(viewModel.value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text(viewModel.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
