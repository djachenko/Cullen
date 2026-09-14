////
////  NavBar.swift
////  Cullen
////
////  Created by justin on 5/3/26.
////
//
//import SwiftUI
//
//
//struct NavBar: View {
//    var viewModel: PhotoViewerViewModel
//
//    var body: some View {
//        VStack {
//            HStack {
//                // Close button
//                Button {
////                    dismiss()
//                } label: {
//                    Image(systemName: "xmark")
//                        .font(Font.system(size: 17, weight: .semibold))
//                        .foregroundColor(.white)
//                        .frame(width: 36, height: 36)
//                        .background(Circle().fill(Color.black.opacity(0.4)))
//                }
//
//                Spacer()
//
//                // Counter
//                Text("\(viewModel.currentIndex + 1) / \(viewModel.totalCount)")
//                    .font(Font.system(size: 15, weight: .semibold))
//                    .foregroundColor(.white)
//                    .shadow(color: .black.opacity(0.5), radius: 4)
//
//                Spacer()
//
//                // Decision badge (if already decided)
//                if let decision = viewModel.decisionFor(viewModel.currentPhoto) {
//                    decisionBadge(decision)
//                } else {
//                    Color.clear.frame(width: 36, height: 36)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.top, 8)
//
//            Spacer()
//        }
//        .background(
//            LinearGradient(
//                colors: [Color.black.opacity(0.5), .clear],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .frame(height: 120)
//            .ignoresSafeArea(),
//            alignment: .top
//        )
//    }
//
//    private func decisionBadge(_ decision: Decision) -> some View {
//        let (icon, color): (String, Color) = switch decision {
//        case .approved: ("checkmark.circle.fill", .green)
//        case .rejected: ("xmark.circle.fill", .red)
//        case .pending:  ("clock.fill", .orange)
//        }
//        
//        return Image(systemName: icon)
//            .font(Font.system(size: 20))
//            .foregroundColor(color)
//            .frame(width: 36, height: 36)
//    }
//}
