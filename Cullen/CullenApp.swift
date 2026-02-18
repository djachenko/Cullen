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
            container.resolve() as PhotosetFeedView
//            .preferredColorScheme(.dark) // Can be changed to .dark or nil
        }
    }
}
