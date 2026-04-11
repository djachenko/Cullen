//
//  CullenNavigationBar.swift
//  Cullen
//
//  Presentation Layer - Reusable Custom Navigation Bar
//
//  Подменяет системный navigation bar, воспроизводя поведение large title:
//  - В свёрнутом состоянии (scrollOffset = 0) показывает большой заголовок
//  - При скролле вниз заголовок схлопывается, появляется инлайн-тайтл в баре
//  - Опционально: размытый cover image как фон всего бара
//
//  Использование в PhotosetFeedView:
//
//      CullenNavigationBar(title: "Photosets", scrollOffset: scrollOffset) {
//          sortMenuButton
//      }
//
//  Использование в PhotosetDetailView:
//
//      CullenNavigationBar(
//          title: "Wedding at Lake Como",
//          scrollOffset: scrollOffset,
//          coverImageURL: viewModel.coverImageURL,
//          subtitle: "342 photos"
//      ) {
//          columnPickerButton
//      }
//

import SwiftUI

// MARK: - Layout Constants (outside generic type)

private enum CullenNavigationBarLayout {
    static let statusBarHeight: CGFloat = 44
    static let navBarHeight:    CGFloat = 44
    static let largeTitleHeight: CGFloat = 52
    static var expandedHeight: CGFloat {
        statusBarHeight + navBarHeight + largeTitleHeight
    }
}

// MARK: - CullenNavigationBar

struct CullenNavigationBar<TrailingContent: View>: View {

    private typealias Layout = CullenNavigationBarLayout

    // MARK: - Configuration

    let title: String
    let scrollOffset: CGFloat
    var subtitle: String? = nil
    var coverImageURL: URL? = nil
    var onDismiss: (() -> Void)? = nil    // nil = no back button (root screen)
    @ViewBuilder var trailingContent: () -> TrailingContent

    // MARK: - Derived State

    /// 0 = fully expanded, 1 = fully collapsed
    private var collapseProgress: CGFloat {
        max(0, min(1, -scrollOffset / Layout.largeTitleHeight))
    }

    private var isCollapsed: Bool { collapseProgress >= 1 }
    private var hasCover: Bool { coverImageURL != nil }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top

            ZStack(alignment: .bottom) {
                // ── Background ──────────────────────────────────────────────
                background
                    .ignoresSafeArea(edges: .top)

                // ── Separator (only visible when collapsed and no cover) ───
                if isCollapsed && !hasCover {
                    Divider()
                        .frame(maxWidth: .infinity, alignment: .bottom)
                }

                // ── Content ─────────────────────────────────────────────────
                VStack(spacing: 0) {
                    // Safe area spacer
                    Spacer().frame(height: safeTop)

                    // Inline bar row: back | inline-title | trailing
                    inlineBar

                    // Large title (collapses)
                    largeTitleRow
                        .frame(height: Layout.largeTitleHeight * (1 - collapseProgress))
                        .clipped()
                }
            }
            // Total height shrinks as large title collapses
            .frame(
                height: safeTop + Layout.navBarHeight + Layout.largeTitleHeight * (1 - collapseProgress),
                alignment: .top
            )
        }
        // The GeometryReader needs an explicit height hint so parent can size itself
        .frame(height: Layout.expandedHeight)
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if let url = coverImageURL {
            ZStack {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        coverPlaceholder
                    }
                }
                .blur(radius: 12, opaque: true)
                .overlay(Color.black.opacity(0.45))
            }
        } else {
            // Standard system-like frosted glass
            Color(.systemBackground)
                .opacity(isCollapsed ? 1 : 0)
                .background(.ultraThinMaterial.opacity(isCollapsed ? 1 : 0))
        }
    }

    private var coverPlaceholder: some View {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.12, blue: 0.22),
                Color(red: 0.08, green: 0.08, blue: 0.15),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Inline Bar Row

    private var inlineBar: some View {
        HStack(spacing: 0) {
            // Back button (optional)
            if let onDismiss {
                backButton(onDismiss: onDismiss)
                    .frame(width: 44, height: Layout.navBarHeight)
            } else {
                Spacer().frame(width: 16)
            }

            Spacer()

            // Inline title — fades in as large title collapses
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(hasCover ? .white : .primary)
                .opacity(collapseProgress)
                .lineLimit(1)

            Spacer()

            // Trailing content
            trailingContent()
                .foregroundColor(hasCover ? .white : .accentColor)
                .frame(height: Layout.navBarHeight)
                .padding(.trailing, 8)
        }
        .frame(height: Layout.navBarHeight)
    }

    // MARK: - Large Title Row

    private var largeTitleRow: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(hasCover ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

//                if let subtitle {
//                    Text(subtitle)
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(hasCover ? .white.opacity(0.75) : .secondary)
//                        .opacity(1 - collapseProgress * 2)
//                }
            }
            .padding(.leading, 16)
            .padding(.bottom, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
    }

    // MARK: - Back Button

    private func backButton(onDismiss: @escaping () -> Void) -> some View {
        Button(action: onDismiss) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                // Show "Back" label only when collapsed (like system behavior)
                if isCollapsed {
                    Text("Back")
                        .font(.system(size: 17))
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .foregroundColor(hasCover ? .white : .accentColor)
            .padding(.leading, 8)
            .animation(.easeInOut(duration: 0.15), value: isCollapsed)
        }
    }
}

// MARK: - View Modifier for easy adoption
//
//extension View {
//    /// Hides the system navigation bar and provides scroll offset for CullenNavigationBar.
//    /// Usage: attach `.cullenNavigationBar(...)` and place CullenNavigationBar in a ZStack overlay.
//    func hidingSystemNavBar() -> some View {
//        self.navigationBarHidden(true)
//    }
//}

// MARK: - Preview

#Preview("No cover — Feed style") {
    NavigationStack {
        ZStack(alignment: .top) {
            ScrollView {
                Color.clear.frame(height: 140) // space for bar
                ForEach(0..<20, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .frame(height: 80)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .ignoresSafeArea(edges: .top)

            CullenNavigationBar(title: "Photosets", scrollOffset: 0) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.system(size: 20))
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview("With cover — Detail style") {
    NavigationStack {
        ZStack(alignment: .top) {
            ScrollView {
                Color.clear.frame(height: 140)
                ForEach(0..<30, id: \.self) { i in
                    Color(.systemGray5).frame(height: 80)
                }
            }
            .ignoresSafeArea(edges: .top)

            CullenNavigationBar(
                title: "Wedding at Lake Como",
                scrollOffset: 0,
                subtitle: "342 photos",
                coverImageURL: URL(string: "https://images.unsplash.com/photo-1519741497674-611481863552?w=800"),
                onDismiss: {}
            ) {
                Image(systemName: "square.grid.3x3")
                    .font(.system(size: 20))
            }
        }
        .navigationBarHidden(true)
    }
}
