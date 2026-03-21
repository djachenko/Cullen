//
//  PhotosetCardView.swift
//  Cullen
//
//  Presentation Layer - Reusable Card Component
//

import SwiftUI
import Kingfisher


struct PhotosetCardView: View {
    @StateObject private var viewModel: PhotosetCardViewModel

    init(viewModel: PhotosetCardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingView
            case .content(let content):
                contentView(content: content)
            case .error:
                errorView
            }
        }
        .task {
            await viewModel.load()
        }
        .onTapGesture {
            viewModel.didTap()
        }
    }
}

extension PhotosetCardView {
    private var loadingView: some View {
        RoundedRectangle(cornerRadius: 16)
//            .fill(Color(.systemBackground))
            .fill(.blue)
            .frame(height: 300)
            .overlay(ProgressView())
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var errorView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .frame(height: 300)
            .overlay(
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.secondary)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func contentView(content: PhotosetCardViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage(url: content.coverUrl)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 11))
                        Text("\(content.photosCount)")
                            .font(.system(size: 13))
                        Spacer()
                        SyncBadgeView(badge: content.syncBadge)
                    }
                    .foregroundColor(.secondary)
                }

                ProgressBarView(progress: content.progressPercentage)

                HStack(spacing: 16) {
                    StatItemView(viewModel: .approved(count: content.approvedCount))
                    StatItemView(viewModel: .rejected(count: content.rejectedCount))
                    StatItemView(viewModel: .pending(count: content.pendingCount))
                    Spacer()
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func coverImage(url: URL?) -> some View {
        KFImage(url)
            .placeholder {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.2),
                            Color(red: 0.1, green: 0.1, blue: 0.15),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .clipped()
    }
}
