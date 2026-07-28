//
//  CullenImage.swift
//  Cullen
//
//  Presentation Layer - KFImage factory with project-wide defaults
//

import SwiftUI
import Kingfisher
import SwinjectAutoregistration


// Resolved once — the cache-events hub every displayed image reports into,
// so casual scrolling feeds the same progress as an explicit sync.
private let cacheReporter: ImageCacheService = Cullen.resolver ~> ImageCacheService.self


@MainActor
func CullenImage(_ url: URL?) -> KFImage {
    KFImage(url)
        .cancelOnDisappear(true)
        .placeholder { CullenImagePlaceholder() }
        .onFailureView { CullenImageFailureView() }
        .onSuccess { _ in
            guard let url else {
                return
            }

            Task { await cacheReporter.report(cached: url) }
        }
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
