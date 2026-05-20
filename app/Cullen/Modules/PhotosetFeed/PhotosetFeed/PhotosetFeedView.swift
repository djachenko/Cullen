//
//  PhotosetFeedView.swift
//  Cullen
//
//  Presentation Layer - Main View (UI Only)
//

import SwiftUI
import Swinject

struct PhotosetFeedView: View {
    @StateObject private var viewModel: PhotosetFeedViewModel
    let resolver: Resolver

    init(viewModel: PhotosetFeedViewModel, resolver: Resolver) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.resolver = resolver
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            switch viewModel.state {
            case .loading, .initial:
                loadingView
            case .content(let content):
                contentView(content: content)
            case .error(let message):
                errorView(message: message)
            }
        }
        .navigationTitle("Photosets")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
        .searchable(
            text: $viewModel.searchText,
            prompt: "Search photosets"
        )
        .task {
            if case .initial = viewModel.state {
                await viewModel.loadPhotosets()
            }
        }
    }

    // MARK: - Content View

    private func contentView(content: PhotosetFeedContent) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                statsHeader(content.statistics)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                LazyVStack(spacing: 16) {
                    ForEach(content.photosetIds, id: \.self) { id in
                        resolver ~> (PhotosetCardView.self, with: id)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .refreshable {
            await viewModel.loadPhotosets()
        }
    }

    // MARK: - Stats Header

    private func statsHeader(_ stats: StatisticsDisplayModel) -> some View {
        HStack(spacing: 12) {
            StatCardView(viewModel: .sets(
                title: "Sets",
                value: stats.totalSetsText,
            ))

            StatCardView(viewModel: .photos(
                title: "Photos",
                value: stats.totalPhotosText,
            ))

            StatCardView(viewModel: .syncing(
                title: "Syncing",
                value: stats.syncingCountText,
            ))
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(viewModel.sortOptions) { option in
                Button {
                    viewModel.didSelectSortOption(option.option)
                } label: {
                    let isSelected = option.option == viewModel.selectedSortOption
                    if isSelected {
                        let directionIcon = if viewModel.sortDirection == .ascending {
                            "chevron.up"
                        } else {
                            "chevron.down"
                        }
                        Label(option.title, systemImage: directionIcon)
                    } else {
                        Label(option.title, systemImage: option.icon)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.system(size: 20))
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading photo sets...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).opacity(0.8))
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Retry") {
                Task {
                    await viewModel.loadPhotosets()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).opacity(0.8))
    }
}


// MARK: - Preview

import SwinjectAutoregistration

#Preview {
    NavigationStack {
        Cullen.resolver ~> PhotosetFeedView.self
    }
}
