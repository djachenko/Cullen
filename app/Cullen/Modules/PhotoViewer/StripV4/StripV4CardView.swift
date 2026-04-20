//
//  StripV4CardView.swift
//  Cullen
//

import SwiftUI
import Kingfisher


struct StripV4CardView: View {
    let photo: Photo
    let decision: Decision

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CullenImage(photo.url)
                .resizable()
                .scaledToFill()
                .clipped()

            DecisionBadge(decision: decision)
                .size(22)
                .padding(16)
        }
    }
}
