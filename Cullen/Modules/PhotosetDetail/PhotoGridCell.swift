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
        KFImage(viewModel.imageURL)
            .placeholder { loadingView }
            .onFailureView { failureView }
            .onSuccess { _ in
                success = true
            }
            .cancelOnDisappear(true)
            .downsampling(size: CGSize(width: width, height: width / aspectRatio))
            .cacheOriginalImage()
            .processingQueue(.dispatch(DispatchQueue.global(qos: .userInitiated)))
            .resizable()
            .scaledToFill()
            .frame(width: width, height: width / aspectRatio)
            .clipped()
    }

    var loadingView: some View {
        ProgressView()
    }

    var failureView: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 24))
            .foregroundColor(.red)
    }

    var decisionBadge: some View {
        DecisionBadge(decision: viewModel.decision)
            .size(16)
    }
}
