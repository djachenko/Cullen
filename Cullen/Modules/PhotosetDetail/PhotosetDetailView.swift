//
//  PhotosetDetailView.swift
//  Cullen
//
//  Created by justin on 15/2/26.
//

import SwiftUI


struct PhotosetDetailView: View {
    let photoSet: PhotosetCardViewModel
    
    var body: some View {
        VStack {
            Text("Photo Set Detail")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(photoSet.name)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("This view will show swipeable photos")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}


import SwinjectAutoregistration

#Preview {
    Cullen.resolver ~> (PhotosetDetailView.self, argument: PhotosetCardViewModel(
        id: .init(),
        name: "",
        photosCountText: "117",
        progressPercentage: 0.72,
        approvedCount: 17,
        rejectedCount: 66,
        pendingCount: 33,
        syncBadge: .init(from: .synced),
        coverImageURL: nil
    ))
}
