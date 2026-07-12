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

        Task {
            await (Cullen.resolver ~> SigningExpirationService.self)
                .scheduleExpirationNotifications()
            await (Cullen.resolver ~> MigrationService.self).runMigrations()
        }
    }

    var body: some Scene {
        WindowGroup {
            Cullen.resolver ~> (AppCoordinatorView.self, with: AppDestination.photosetFeed)
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
        SystemAssembly(),
        MigrationsAssembly(),
        LoggingAssembly(),
    ]).resolver
}
