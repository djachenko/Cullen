//
//  StripV4View.swift
//  Cullen
//

import SwiftUI
import Kingfisher

// MARK: - StripV4View

struct StripV4View: View {

    @ObservedObject var viewModel: PhotoViewerViewModel

    @State private var scrollPosition: PhotoId?

    private enum Layout {
        static let cardSpacing: CGFloat = 20
        static let defaultAspectRatio: CGFloat = 3.0 / 2.0
        static let cornerRadius: CGFloat = 4
    }

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            let cardHeight = cardWidth / Layout.defaultAspectRatio
            let edgeInset = max((geometry.size.height - cardHeight) / 2, 0)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: Layout.cardSpacing) {
                    Color.clear.frame(height: edgeInset)

                    ForEach(viewModel.photos) { photo in
                        StripV4CardView(
                            photo: photo,
                            decision: viewModel.decisions[photo.id] ?? .pending,
                            width: cardWidth,
                            height: cardHeight,
                            isActive: scrollPosition == photo.id
                        )
                        .id(photo.id)
                    }

                    Color.clear.frame(height: edgeInset)
                }
                .scrollTargetLayout()
            }
            .background(Color.black)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .onAppear {
                UIScrollView.appearance().decelerationRate = .fast

                guard viewModel.photos.indices.contains(viewModel.currentIndex) else {
                    return
                }

                scrollPosition = viewModel.photos[viewModel.currentIndex].id
            }
            .onDisappear {
                UIScrollView.appearance().decelerationRate = .normal
            }
        }
        .ignoresSafeArea()
        .onChange(of: scrollPosition) { _, id in
            guard let id,
                  let index = viewModel.photos.firstIndex(where: { $0.id == id }),
                  viewModel.currentIndex != index else {
                return
            }
            viewModel.currentIndex = index
        }
        .onChange(of: viewModel.currentIndex) { _, newIndex in
            guard viewModel.photos.indices.contains(newIndex) else {
                return
            }

            let id = viewModel.photos[newIndex].id

            guard id != scrollPosition else {
                return
            }

            scrollPosition = id
        }
    }
}

// MARK: - Card View

private struct StripV4CardView: View {
    let photo: Photo
    let decision: Decision
    let width: CGFloat
    let height: CGFloat
    let isActive: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CullenImage(photo.url)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()

            DecisionBadge(decision: decision)
                .size(22)
                .padding(16)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(isActive ? 0.24 : 0.12), radius: 18, x: 0, y: 10)
    }
}
