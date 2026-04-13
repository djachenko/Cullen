//
//  CullenImage.swift
//  Cullen
//
//  Presentation Layer - KFImage factory with project-wide defaults
//

import SwiftUI
import Kingfisher


@MainActor
func CullenImage(_ url: URL?) -> KFImage {
    KFImage(url)
        .cancelOnDisappear(true)
        .placeholder { CullenImagePlaceholder() }
        .onFailureView { CullenImageFailureView() }
}


struct CullenImagePlaceholder: View {
    var body: some View {
        ProgressView()
    }
}


struct CullenImageFailureView: View {
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 24))
            .foregroundColor(.red)
    }
}
