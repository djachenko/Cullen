//
//  AppCoordinator.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI
import Swinject
import Combine

// TODO: maybe move to another file
protocol Coordinator {
    func show(_ destination: AppDestination)
}

final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    let root: AppDestination
    let resolver: Resolver

    init(
        root: AppDestination,
        resolver: Resolver,
    ) {
        self.root = root
        self.resolver = resolver
    }
}

extension AppCoordinator: Coordinator {
    func show(_ destination: AppDestination) {
        path.append(destination)
    }
}

// TODO: move to another file
final class MockCoordinator: Coordinator {
    func show(_ destination: AppDestination) {
        print("will show \(destination)")
    }
}
