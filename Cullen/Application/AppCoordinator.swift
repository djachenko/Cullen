//
//  AppCoordinator.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import SwiftUI
import Combine


protocol Coordinator {
    func show(_ destination: AppDestination)
}

final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
}

extension AppCoordinator: Coordinator {
    func show(_ destination: AppDestination) {
        path.append(destination)
    }
}
