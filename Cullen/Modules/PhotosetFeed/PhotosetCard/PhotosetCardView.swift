//
//  PhotosetCardView.swift
//  Cullen
//
//  Presentation Layer - Reusable Card Component
//

import SwiftUI

struct PhotosetCardView: View {
    let photoSet: PhotosetCardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover Image
            coverImage
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(photoSet.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 11))
                        
                        Text(photoSet.photosCountText)
                            .font(.system(size: 13))
                        
                        Spacer()
                        
                        SyncBadgeView(badge: photoSet.syncBadge)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Progress Bar
                ProgressBarView(progress: photoSet.progressPercentage)
                
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
            if let imageURL = photoSet.coverImageURL {
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
                viewModel: .approved(count: photoSet.approvedCount)
            )
            
            StatItemView(
                viewModel: .rejected(count: photoSet.rejectedCount)
            )
            
            StatItemView(
                viewModel: .pending(count: photoSet.pendingCount)
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
        photoSet: PhotosetCardViewModel(
            from: Photoset(
                id: UUID(),
                name: "Wedding at Lake Como",
                remotePath: "/photosets/wedding",
                syncStatus: .error,
                lastSyncDate: Date(),
                createdAt: Date(),
                coverImageURL: URL(string: "https://images.unsplash.com/photo-1519741497674-611481863552?w=800"),
                photosCount: 342,
                approvedCount: 128,
                rejectedCount: 89
            )
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
