//
//  ParamsMap.swift
//  Cullen
//

import Swinject


struct ParaMap {
    private var registrators: [(Container) -> Void] = []

    mutating func set<T>(_ value: T) {
        registrators.append { container in
            container.register(T.self) { _ in value }
        }
    }

    func apply(to container: Container) {
        registrators.forEach { $0(container) }
    }
}


extension Resolver {
    func resolve<T>(_ type: T.Type, params: ParaMap) -> T? {
        guard let container = self as? Container else {
            fatalError("Resolver is not a Container — cannot create child for ParaMap")
        }

        let child = Container(parent: container)
        child.register(Resolver.self) { _ in child }
        params.apply(to: child)

        return child.resolve(type)
    }
}


private func resolved<T>(_ type: T.Type, from resolver: Resolver, params: ParaMap) -> T {
    guard let value = resolver.resolve(type, params: params) else {
        fatalError("Swinject: failed to resolve \(T.self)")
    }

    return value
}

func ~> <T, A>(resolver: Resolver, pair: (T.Type, with: A)) -> T {
    var params = ParaMap()
    params.set(pair.1)

    return resolved(pair.0, from: resolver, params: params)
}

func ~> <T, A, B>(resolver: Resolver, pair: (T.Type, with: A, B)) -> T {
    var params = ParaMap()
    params.set(pair.1)
    params.set(pair.2)

    return resolved(pair.0, from: resolver, params: params)
}

func ~> <T, A, B, C>(resolver: Resolver, pair: (T.Type, with: A, B, C)) -> T {
    var params = ParaMap()
    params.set(pair.1)
    params.set(pair.2)
    params.set(pair.3)

    return resolved(pair.0, from: resolver, params: params)
}

func ~> <T, A, B, C, D>(resolver: Resolver, pair: (T.Type, with: A, B, C, D)) -> T {
    var params = ParaMap()
    params.set(pair.1)
    params.set(pair.2)
    params.set(pair.3)
    params.set(pair.4)

    return resolved(pair.0, from: resolver, params: params)
}

func ~> <T, A, B, C, D, E>(resolver: Resolver, pair: (T.Type, with: A, B, C, D, E)) -> T {
    var params = ParaMap()
    params.set(pair.1)
    params.set(pair.2)
    params.set(pair.3)
    params.set(pair.4)
    params.set(pair.5)

    return resolved(pair.0, from: resolver, params: params)
}
