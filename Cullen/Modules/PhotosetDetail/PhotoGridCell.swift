//
//  PhotoGridCell.swift
//  Cullen
//
//  Created by justin on 7/3/26.
//

import SwiftUI
import Kingfisher


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
    let width: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            photoImage
            decisionBadge.padding(6)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .onTapGesture { viewModel.onTap() }
    }

    private var photoImage: some View {
        KFImage(viewModel.imageURL)
            .placeholder { placeholder }
            .cancelOnDisappear(true)
            .downsampling(size: CGSize(width: width, height: width / aspectRatio))
            .processingQueue(.dispatch(DispatchQueue.global(qos: .userInitiated)))
            .resizable()
            .scaledToFill()
            .frame(width: width, height: width / aspectRatio)
            .clipped()
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
