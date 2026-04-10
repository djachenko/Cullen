//
//  PhotosetDetailView.swift
//  Cullen
//
//  Presentation Layer - Photoset Detail Screen
//

import SwiftUI


struct PhotosetDetailView: View {
    @State private var columnCount: Int = 3
    @State private var gridWidth: CGFloat = 0
    @StateObject private var viewModel: PhotosetDetailViewModel

    @State private var scrollTarget: PhotoId? = nil

    init(viewModel: PhotosetDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch viewModel.state {
                case .initial, .loading:
                    loadingView
                case .content(let content):
                    contentView(content: content)
                case .error(let message):
                    errorView(message: message)
                }
            }
            .onAppear {
                gridWidth = geometry.size.width
            }
            .onChange(of: geometry.size.width) { _, width in
                gridWidth = width
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    prefetchButton
                    exportButton
                    columnPicker
                }
            }
        }
        .task {
            await viewModel.loadPhotos()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

// MARK: Toolbar items

private extension PhotosetDetailView {
    @ViewBuilder
    var prefetchButton: some View {
        Button {
            viewModel.didTapPrefetchButton()
        } label: {
            switch viewModel.prefetchState {
                case .notCached:
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 20))
                case .partial(let ratio):
                    CircularProgress(value: ratio, color: .yellow)
                        .frame(width: 20, height: 20)
                case .prefetching(let progress):
                    CircularProgress(value: progress, color: .accentColor)
                        .frame(width: 20, height: 20)
                case .full:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
            }
        }
    }

    //    TODO: viewbuilder
    var exportButton: some View {
        Group {
            if let export = viewModel.export {
                ShareLink(
                    item: export,
                    preview: SharePreview(
                        export.filename,
                        image: Image(systemName: "doc.text")
                    )
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                }
            } else {
                Button {
                    viewModel.exportDecisions()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                }
                .disabled(viewModel.state.isLoading)
            }
        }
    }

    var columnPicker: some View {
        Menu {
            Picker("Columns", selection: $columnCount) {
                Label("2 Columns", systemImage: "square.grid.2x2").tag(2)
                Label("3 Columns", systemImage: "square.grid.3x3").tag(3)
                Label("4 Columns", systemImage: "square.grid.4x3.fill").tag(4)
            }
        } label: {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 20))
        }
    }
}

extension PhotosetDetailView {
    private var loadingView: some View {
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
        if content.isEmpty {
            emptyView
        } else {
            grid(photos: content)
        }
    }

    private func grid(photos: [PhotoGridCellViewModel]) -> some View {
        let spacing = 2.0
        let columnWidth = (gridWidth - spacing * Double(columnCount - 1)) / Double(columnCount)

        return ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(columnWidth), spacing: spacing),
                    count: columnCount
                ),
                spacing: spacing
            ) {
                ForEach(photos) { photo in
                    PhotoGridCell(
                        viewModel: photo,
                        aspectRatio: viewModel.aspectRatio,
                        width: columnWidth
                    )
                    .id(photo.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollTarget, anchor: .center)
        .overlay(alignment: .bottomTrailing) {
            viewModel.nextPendingId.map {
                scrollToNextButton(nextId: $0)
            }
        }
        .onScrollTargetVisibilityChange(idType: PhotoId.self) { visibleIds in
            viewModel.didShow(photoIds: visibleIds)
//            viewModel.prefetchAhead(after: visibleIds.last)
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

            Button("Retry") {
                Task {
                    await viewModel.loadPhotos()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func scrollToNextButton(nextId: PhotoId) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollTarget = nextId
            }
        } label: {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white, .blue)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .padding(.bottom, 24)
        .padding(.trailing, 20)
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        PreviewWrapper()
    }
}

import SwinjectAutoregistration

private struct PreviewWrapper: View {
    @State private var photosetId: PhotosetId?

    var body: some View {
        Group {
            if let photosetId {
                Cullen.resolver ~> (PhotosetDetailView.self, with: photosetId)
            } else {
                ProgressView()
                    .task {
                        let repository = Cullen.resolver ~> PhotosetsRepository.self
                        let photosetIds = try? await repository.getPhotosetIds()

                        photosetId = photosetIds?.first
                    }
            }
        }
    }
}
