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
        .task {
            await viewModel.prepareSync()
        }
        .onTapGesture {
            viewModel.didTap()
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            viewModel.didLongPress()
        }
    }
}

private extension PhotosetCardView {
    var loadingView: some View {
        RoundedRectangle(cornerRadius: 16)
//            .fill(Color(.systemBackground))
            .fill(.blue)
            .frame(height: 300)
            .overlay(ProgressView())
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    var errorView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .frame(height: 300)
            .overlay(
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.secondary)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    func contentView(content: PhotosetCardViewModel.Content) -> some View {
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    Color(.separator).opacity(0.5),
                    lineWidth: 2
                )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 4
        )
    }

    func coverImage(url: URL?) -> some View {
        CullenImage(url)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 200)
            .clipped()
            .overlay(alignment: .bottom) {
                cacheSyncIndicator
            }
    }

    @ViewBuilder
    var cacheSyncIndicator: some View {
        let progress = viewModel.progress

        if progress > 0 {

            let color: Color = if progress == 1 {
                .green
            } else if viewModel.isSyncing {
                .accentColor
            } else {
                .secondary
            }

            GeometryReader { geometry in
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
            }
            .frame(height: 3)
        }
    }
}
