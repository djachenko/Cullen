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
    @State private var gate = Cullen.resolver ~> MigrationGate.self

    init() {
        KingfisherConfiguration.configure()

        // Своей таской: диалог пермишена на нотификации подвешивает её на неопределённое
        // время, и миграции не должны ждать, пока пользователь до него доберётся.
        Task {
            await (Cullen.resolver ~> (SigningExpirationService.self, with: LogCategory.app))
                .scheduleExpirationNotifications()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if gate.isReady {
                    Cullen.resolver ~> (AppCoordinatorView.self, with: AppDestination.photosetFeed)
                } else {
                    ProgressView()
                }
            }
            .task {
                await gate.open()
            }
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
