//
//  LoggingAssembly.swift
//  Cullen
//

import Swinject
import SwinjectAutoregistration


final class LoggingAssembly: Assembly {
    func assemble(container: Container) {
        container.register(LogBackend.self) { _ in
            var backends: [LogBackend] = [OSLogBackend()]

            #if DEBUG
            backends.append(ConsoleLogBackend())
            #endif

            return CompositeLogBackend(backends: backends)
        }
        .inObjectScope(.container)

        container.autoregister(LoggerImpl.init)
            .implements(Logger.self)
    }
}
