//
//  PhotosetFeedView.swift
//  CullenApp
//
//  Presentation Layer - Main View (UI Only)
//

import SwiftUI

struct PhotosetFeedView: View {
    @StateObject private var viewModel: PhotosetFeedViewModel

    init(viewModel: PhotosetFeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
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
    }

    // MARK: - Content View

    private func contentView(content: PhotosetFeedContent) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                statsHeader(content.statistics)
                    .transition(.opacity.combined(with: .move(edge: .top)))

                // Photo Sets List
                LazyVStack(spacing: 16) {
                    ForEach(content.photosets) { photoset in
                        NavigationLink {
                            PhotosetDetailView(photoSet: photoset)
                        } label: {
                            PhotosetCardView(photoSet: photoset)
                        }
                        .buttonStyle(CardButtonStyle())
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
            Picker("Sort by", selection: $viewModel.selectedSortOption) {
                ForEach(viewModel.sortOptions) { option in
                    Label(option.title, systemImage: option.icon)
                        .tag(option.option)
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

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

import DITranquillity

#Preview {
    CullenDI.container.resolve() as PhotosetFeedView
}
