//
//  CullenApp.swift
//  Cullen
//
//  App Entry Point
//

import SwiftUI
import Swinject
import SwinjectAutoregistration

@main
struct Cullen: App {
    init() {
        KingfisherConfiguration.configure()
    }

    var body: some Scene {
        WindowGroup {
            Cullen.resolver ~> (AppCoordinatorView.self, argument: AppDestination.photosetFeed)
        }
    }
}

extension Cullen {
    static let resolver = Assembler([
        RepositoriesAssembly(),
        UseCasesAssembly(),
        PhotosetFeedAssembly(),
        PhotosetDetailAssembly(),
        PhotoViewerAssembly(),
        AppAssembly(),
    ]).resolver
}
