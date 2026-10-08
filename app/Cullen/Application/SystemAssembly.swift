//
//  SystemAssembly.swift
//  Cullen
//
//  Created by justin on 21/3/26.
//

import Foundation
import Kingfisher
import Swinject
import UserNotifications


final class SystemAssembly: Assembly {
    func assemble(container: Container) {
        container.register(Resolver.self) { $0 }
            .inObjectScope(.weak)

        container.register(FileManager.self) { _ in
            .default
        }.inObjectScope(.weak)

        container.register(UserDefaults.self) { _ in
            .standard
        }.inObjectScope(.weak)

        container.register(CullenImageCache.self) { _ in
            // Same name as ImageCache.default — keeps pointing at the existing cache directory.
            CullenImageCache(name: "default")
        }
        .inObjectScope(.container)
        .implements(ImageCache.self)

        container.register(UNUserNotificationCenter.self) { _ in
            .current()
        }.inObjectScope(.weak)

        container.autoregister(SigningExpirationService.init)
            .inObjectScope(.container)
    }
}
