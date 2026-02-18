//
//  AppDestination.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI
import DITranquillity


enum AppDestination: Hashable {
    case photosetFeed
    case photosetDetail(PhotosetCardViewModel)

    @ViewBuilder
    func view(in container: DIContainer) -> some View {
        switch self {
        case .photosetFeed:
            container.resolve() as PhotosetFeedView
        case .photosetDetail(let photoset):
            container.resolve(args: photoset) as PhotosetDetailView
        }
    }
}
