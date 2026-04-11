//
//  ParaMap.swift
//  Cullen
//

import Swinject


struct ParaMap {
    private var registrators: [(Container) -> Void] = []

    init<each A>(_ values: repeat each A) {
        repeat set(each values)
    }

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
    resolved(
        pair.0,
        from: resolver,
        params: ParaMap(
            pair.1
        )
    )
}

func ~> <T, A, B>(resolver: Resolver, pair: (T.Type, with: A, B)) -> T {
    resolved(
        pair.0,
        from: resolver,
        params: ParaMap(
            pair.1,
            pair.2
        )
    )
}

func ~> <T, A, B, C>(resolver: Resolver, pair: (T.Type, with: A, B, C)) -> T {
    resolved(
        pair.0,
        from: resolver,
        params: ParaMap(
            pair.1,
            pair.2,
            pair.3
        )
    )
}

func ~> <T, A, B, C, D>(resolver: Resolver, pair: (T.Type, with: A, B, C, D)) -> T {
    resolved(
        pair.0,
        from: resolver,
        params: ParaMap(
            pair.1,
            pair.2,
            pair.3,
            pair.4
        )
    )
}

func ~> <T, A, B, C, D, E>(resolver: Resolver, pair: (T.Type, with: A, B, C, D, E)) -> T {
    resolved(
        pair.0,
        from: resolver,
        params: ParaMap(
            pair.1,
            pair.2,
            pair.3,
            pair.4,
            pair.5
        )
    )
}
