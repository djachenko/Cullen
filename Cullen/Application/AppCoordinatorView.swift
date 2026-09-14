//
//  AppCoordinatorView.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI
import Swinject
import SwinjectAutoregistration


struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator

    let root: AppDestination
    let resolver: Resolver

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            view(for: root)
                .navigationDestination(for: AppDestination.self) { destination in
                    view(for: destination)
                }
        }
    }

    @ViewBuilder
    private func view(for destination: AppDestination) -> some View {
        switch destination {
            case .photosetFeed:
                resolver ~> PhotosetFeedView.self
            case .photosetDetail(let id):
                resolver ~> (PhotosetDetailView.self, with: id, LogCategory.detail)
            case .photoViewer(
                let photos,
                let index,
                let photosetId
            ):
                resolver ~> (
                    PhotoViewerView.self,
                    with: photos,
                    index,
                    photosetId,
                    LogCategory.viewer
                )
        }
    }
}
