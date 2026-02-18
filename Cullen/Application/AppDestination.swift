//
//  AppDestination.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI
import Swinject
import SwinjectAutoregistration


enum AppDestination: Hashable {
    case photosetFeed
    case photosetDetail(PhotosetCardViewModel)

    @ViewBuilder
    func view(from resolver: Resolver) -> some View {
        switch self {
        case .photosetFeed:
            resolver ~> PhotosetFeedView.self
        case .photosetDetail(let photoset):
            resolver ~> (PhotosetDetailView.self, argument: photoset)
        }
    }
}
