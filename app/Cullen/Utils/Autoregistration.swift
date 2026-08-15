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

    // Ключ живёт в ServiceKey.option — том же поле, через которое SwinjectStoryboard
    // различает регистрации. Участвует в hash/== ключа наравне с типом, так что
    // ключом может быть любой Hashable, а не строковое имя.
    @discardableResult
    func autoregister<S, each A>(
        _ type: S.Type,
        key: some ServiceKeyOption,
        initializer: @escaping (repeat each A) -> S
    ) -> ServiceEntry<S> {
        _register(
            S.self,
            factory: { (r: Resolver) in
                initializer(repeat resolved((each A).self, from: r))
            },
            option: key
        )
    }
}


func ~> <T>(resolver: Resolver, key: some ServiceKeyOption) -> T {
    guard let container = resolver as? Container else {
        fatalError("Resolver is not a Container — cannot resolve by key")
    }

    let value: T? = container._resolve(name: nil, option: key) { (factory: (Resolver) -> Any) in
        factory(container)
    }

    guard let value else {
        fatalError("Swinject: failed to resolve \(T.self) for key \(key)")
    }

    return value
}
