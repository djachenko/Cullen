//
//  SyncBadgeView.swift
//  Cullen
//
//  Created by justin on 14/2/26.
//

import SwiftUI

struct SyncBadgeView: View {
    let badge: SyncBadgeViewModel

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badge.color)
                .frame(width: 6, height: 6)

            Text(badge.text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(badge.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badge.color.opacity(0.12))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(alignment: .trailing) {
        SyncBadgeView(badge: .init(from: .synced))
        SyncBadgeView(badge: .init(from: .pending))
        SyncBadgeView(badge: .init(from: .error))
    }
}
