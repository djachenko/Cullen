//
//  AppDestination.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI
import Swinject
import SwinjectAutoregistration

//protocol AppDest: Hashable {
//    func view(from resolver: Resolver) -> any View
//}


// TODO: think about moving to protocol
enum AppDestination: Hashable {
    case photosetFeed
    case photosetDetail(PhotosetInfo)
    case photoViewer(photos: [Photo], startIndex: Int)

    @ViewBuilder
    func view(from resolver: Resolver) -> some View {
        switch self {
            case .photosetFeed:
                resolver ~> PhotosetFeedView.self
            case .photosetDetail(let photoset):
                resolver ~> (PhotosetDetailView.self, argument: photoset)
            case .photoViewer(let photos, let index):
                resolver ~> (PhotoViewerView.self, arguments: (photos, index))
        }
    }
}
