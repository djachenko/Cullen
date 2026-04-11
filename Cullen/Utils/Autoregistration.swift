//
//  Autoregistration.swift
//  Cullen
//

import Swinject


private func resolved<T>(_ type: T.Type, from resolver: Resolver) -> T {
    guard let value = resolver.resolve(type) else {
        fatalError("Swinject: failed to resolve \(T.self)")
    }

    return value
}


extension Container {
    @discardableResult
    func autoregister<S, each A>(_ initializer: @escaping (repeat each A) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(repeat resolved((each A).self, from: r))
        }
    }
}
