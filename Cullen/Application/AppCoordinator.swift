//
//  AppCoordinator.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI
import DITranquillity
import Combine


final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    let root: AppDestination
    let container: DIContainer

    init(
        root: AppDestination,
        container: DIContainer,
    ) {
        self.root = root
        self.container = container
    }

    func show(_ destination: AppDestination) {
        path.append(destination)
    }
}
