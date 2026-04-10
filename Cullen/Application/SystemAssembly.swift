//
//  SystemAssembly.swift
//  Cullen
//
//  Created by justin on 21/3/26.
//

import Foundation
import Swinject


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
    }
}
