//
//  PhotosetDetailView.swift
//  Cullen
//
//  Presentation Layer - Photoset Detail Screen
//

import SwiftUI


struct PhotosetDetailView: View {
    @State private var columnCount: Int = 3
    @ObservedObject var viewModel: PhotosetDetailViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            switch viewModel.state {
                case .initial, .loading:
                    loaingView
                case .content(let content):
                    contentView(content: content)
                case .error(let message):
                    errorView(message: message)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { columnPicker }
        }
        .task {
            if case .initial = viewModel.state {
                await viewModel.loadPhotos()
            }
        }
    }

    // MARK: - Column Picker

    private var columnPicker: some View {
        Menu {
            Picker("Columns", selection: $columnCount) {
                Label(
                    "2 Columns",
                    systemImage: "square.grid.2x2"
                )
                .tag(2)

                Label(
                    "3 Columns",
                    systemImage: "square.grid.3x3"
                )
                .tag(3)

                Label(
                    "4 Columns",
                    systemImage: "square.grid.4x3.fill"
                )
                .tag(4)
            }
        } label: {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 20))
        }
    }

    // MARK: - Photo Content

    private var loaingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading photos...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    @ViewBuilder
    private func contentView(content: PhotosetDetailContent) -> some View {
        let photos = content

        if photos.isEmpty {
            emptyView
        } else {
            grid(photos: photos)
        }
    }

    private func grid(photos: [PhotoGridCellViewModel]) -> some View {
        return LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: 2
                ),
                count: columnCount
            ),
            spacing: 2
        ) {
            ForEach(photos) { photo in
                PhotoGridCell(
                    viewModel: photo,
                    aspectRatio: viewModel.aspectRatio
                )
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.secondary)

            Text("No photos match the selected filters")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }

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

            Button("Retry") { Task { await viewModel.loadPhotos() } }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Preview

import SwinjectAutoregistration

#Preview {
    NavigationStack {
        PreviewWrapper()
    }
}

private struct PreviewWrapper: View {
    @State private var photosetInfo: PhotosetInfo?

    var body: some View {
        Group {
            if let photosetInfo {
                Cullen.resolver ~> (PhotosetDetailView.self, argument: photosetInfo)
            } else {
                ProgressView()
                    .task {
                        let repository = Cullen.resolver ~> PhotosetsRepository.self

                        photosetInfo = try? await repository.getPhotosets()
                            .first
                            .map { PhotosetInfo(photoset: $0) }
                    }
            }
        }
    }
}
