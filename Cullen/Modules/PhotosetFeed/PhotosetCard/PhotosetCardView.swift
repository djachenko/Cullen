//
//  PhotosetCardView.swift
//  Cullen
//
//  Presentation Layer - Reusable Card Component
//

import SwiftUI

struct PhotosetCardView: View {
    let photoset: PhotosetCardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover Image
            coverImage
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(photoset.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 11))
                        
                        Text(photoset.photosCountText)
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        SyncBadgeView(badge: photoset.syncBadge)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Progress Bar
                ProgressBarView(progress: photoset.progressPercentage)
                
                // Stats
                statsRow
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    // MARK: - Subviews
    
    private var coverImage: some View {
        Group {
            if let imageURL = photoset.coverImageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderImage
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 200)
        .clipped()
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.2),
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.3))
        }
    }
    
    
    
    private var statsRow: some View {
        HStack(spacing: 16) {
            StatItemView(
                viewModel: .approved(count: photoset.approvedCount)
            )
            
            StatItemView(
                viewModel: .rejected(count: photoset.rejectedCount)
            )
            
            StatItemView(
                viewModel: .pending(count: photoset.pendingCount)
            )
            
            Spacer()
        }
    }
}

// MARK: - Stat Item Component



// MARK: - Corner Radius Extension
//
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}

//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//    
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(
//            roundedRect: rect,
//            byRoundingCorners: corners,
//            cornerRadii: CGSize(width: radius, height: radius)
//        )
//        return Path(path.cgPath)
//    }
//}

// MARK: - Preview

#Preview {
    PhotosetCardView(
        photoset: PhotosetCardViewModel(
            from: PhotosetInfo(
                id: .mock,
                title: "Wedding at Lake Como",
                coverUrl: URL(string: "https://images.unsplash.com/photo-1519741497674-611481863552?w=800"),
                photosCount: 342,
                approvedCount: 128,
                rejectedCount: 89,
            )
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
