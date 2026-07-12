//
//  LoggingAssembly.swift
//  Cullen
//

import Swinject
import SwinjectAutoregistration


final class LoggingAssembly: Assembly {
    func assemble(container: Container) {
        container.register(LogBackend.self) { _ in
            #if DEBUG
            return ConsoleLogBackend()
            #else
            return OSLogBackend()
            #endif
        }
        .inObjectScope(.container)

        container.autoregister(LoggerImpl.init)
            .implements(Logger.self)
    }
}
