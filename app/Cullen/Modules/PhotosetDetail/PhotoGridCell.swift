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

    @State var success = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            photoImage

            if success {
                decisionBadge.padding(6)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .onTapGesture { viewModel.onTap() }
    }
}

private extension PhotoGridCell{
    var photoImage: some View {
        CullenImage(viewModel.imageURL)
            .onSuccess { _ in
                success = true
            }
            .downsampling(size: CGSize(width: width, height: width / aspectRatio))
            .resizable()
            .scaledToFill()
            .frame(width: width, height: width / aspectRatio)
            .clipped()
    }

    var decisionBadge: some View {
        DecisionBadge(decision: viewModel.decision)
            .size(16)
    }
}
