//
//  SystemAssembly.swift
//  Cullen
//
//  Created by justin on 21/3/26.
//

import Foundation
import Kingfisher
import Swinject
import SwinjectAutoregistration
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

        container.register(KingfisherManager.self) { _ in
            .shared
        }.inObjectScope(.weak)

        container.register(CullenImageCache.self) { _ in
            // Same name as ImageCache.default — keeps pointing at the existing cache directory.
            CullenImageCache(name: "default")
        }
        .implements(ImageCache.self)
        .inObjectScope(.container)
        // KingfisherConfiguration resolves the cache before anything is shown,
        // so the delegate is in place before the first write can happen.
        .initCompleted { resolver, cache in
            cache.delegate = resolver ~> ImageCacheDelegate.self
        }

        container.register(UNUserNotificationCenter.self) { _ in
            .current()
        }.inObjectScope(.weak)

        container.autoregister(SigningExpirationService.init)
            .inObjectScope(.container)
    }
}
