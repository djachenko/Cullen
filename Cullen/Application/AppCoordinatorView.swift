//
//  AppCoordinatorView.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI


struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            viewBuilder(coordinator.root)
                .navigationDestination(for: AppDestination.self, destination: viewBuilder)
        }
    }
}

private extension AppCoordinatorView {
    func viewBuilder(_ destination: AppDestination) -> some View {
        destination.view(from: coordinator.resolver)
    }
}
