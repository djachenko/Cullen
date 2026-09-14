//
//  StatItemView.swift
//  Cullen
//
//  Created by justin on 15/2/26.
//

import SwiftUI


struct StatItemView: View {
    let viewModel: StatItemViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.icon)
                .font(.system(size: 12))
                .foregroundColor(viewModel.color)

            Text("\(viewModel.value)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}
