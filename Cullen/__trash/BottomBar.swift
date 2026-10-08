////
////  BottomBar.swift
////  Cullen
////
////  Created by justin on 5/3/26.
////
//
//import SwiftUI
//
//
//struct BottomBar: View {
//    var viewModel: PhotoViewerViewModel
//
//    var body: some View {
//        VStack {
//            Spacer()
//
//            HStack(spacing: 0) {
//                // Previous
//                actionButton(
//                    icon: "chevron.left",
//                    label: "Prev",
//                    color: .white.opacity(0.7),
//                    enabled: viewModel.hasPrevious
//                ) {
//                    viewModel.goToPrevious()
//                }
//
//                Spacer()
//
//                // Reject
//                actionButton(
//                    icon: SwipeDirection.left.icon,
//                    label: SwipeDirection.left.label,
//                    color: SwipeDirection.left.color,
//                    enabled: true
//                ) {
//                    viewModel.commitSwipe(.left)
//                }
//
//                Spacer()
//
//                // Skip
//                actionButton(
//                    icon: SwipeDirection.up.icon,
//                    label: SwipeDirection.up.label,
//                    color: SwipeDirection.up.color,
//                    enabled: true
//                ) {
//                    viewModel.commitSwipe(.up)
//                }
//
//                Spacer()
//
//                // Approve
//                actionButton(
//                    icon: SwipeDirection.right.icon,
//                    label: SwipeDirection.right.label,
//                    color: SwipeDirection.right.color,
//                    enabled: true
//                ) {
//                    viewModel.commitSwipe(.right)
//                }
//
//                Spacer()
//
//                // Next
//                actionButton(
//                    icon: "chevron.right",
//                    label: "Next",
//                    color: .white.opacity(0.7),
//                    enabled: viewModel.hasNext
//                ) {
//                    viewModel.goToNext()
//                }
//            }
//            .padding(.horizontal, 24)
//            .padding(.bottom, 8)
//        }
//        .background(
//            LinearGradient(
//                colors: [.clear, Color.black.opacity(0.55)],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .frame(height: 140)
//            .ignoresSafeArea(),
//            alignment: .bottom
//        )
//    }
//
//    private func actionButton(
//        icon: String,
//        label: String,
//        color: Color,
//        enabled: Bool,
//        action: @escaping () -> Void
//    ) -> some View {
//        Button(action: action) {
//            VStack(spacing: 4) {
//                Image(systemName: icon)
//                    .font(Font.system(size: 22, weight: .semibold))
//                Text(label)
//                    .font(Font.system(size: 10, weight: .medium))
//            }
//            .foregroundColor(color)
//            .opacity(enabled ? 1 : 0.3)
//        }
//        .disabled(!enabled)
//        .buttonStyle(.plain)
//    }
//}
