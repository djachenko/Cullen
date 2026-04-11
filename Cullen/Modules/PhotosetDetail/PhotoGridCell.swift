//
//  PhotoGridCell.swift
//  Cullen
//
//  Created by justin on 7/3/26.
//

import SwiftUI

struct PhotoGridCellViewModel {
    let id: String
    let imageURL: URL?
    let decision: Decision

    let onTap: () -> Void
}

extension PhotoGridCellViewModel: Identifiable {}


struct PhotoGridCell: View {
    let viewModel: PhotoGridCellViewModel
    let aspectRatio: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                photoImage
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.width / aspectRatio
                    )
                    .clipped()

                decisionBadge
                    .padding(6)
            }
            .onTapGesture {
                viewModel.onTap()
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    // MARK: - Subviews

    private var photoImage: some View {
        Group {
            if let url = viewModel.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "photo")
                .foregroundColor(.secondary)
                .font(.system(size: 20))
        }
    }

    private var decisionBadge: some View {
        Group {
            switch viewModel.decision {
            case .approved:
                badge(icon: "checkmark.circle.fill", color: .green)
            case .rejected:
                badge(icon: "xmark.circle.fill", color: .red)
            case .pending:
                EmptyView()
            }
        }
    }

    private func badge(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}
