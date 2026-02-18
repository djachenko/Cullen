//
//  CullenApp.swift
//  CullenApp
//
//  App Entry Point
//

import SwiftUI
import DITranquillity

@main
struct CullenApp: App {
    // Dependency Injection Container
    private let container = CullenDI.container

    var body: some Scene {
        WindowGroup {
            let arguments = AnyArguments(for: AppCoordinator.self, args: AppDestination.photosetFeed)

            container.resolve(arguments: arguments) as AppCoordinatorView
        }
    }
}
