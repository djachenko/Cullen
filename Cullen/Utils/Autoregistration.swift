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
    func autoregister<S>(_ initializer: @escaping () -> S) -> ServiceEntry<S> {
        register(S.self) { _ in
            initializer()
        }
    }

    @discardableResult
    func autoregister<S, A>(_ initializer: @escaping (A) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r)
            )
        }
    }

    @discardableResult
    func autoregister<S, A, B>(_ initializer: @escaping (A, B) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r),
                resolved(B.self, from: r)
            )
        }
    }

    @discardableResult
    func autoregister<S, A, B, C>(_ initializer: @escaping (A, B, C) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r),
                resolved(B.self, from: r),
                resolved(C.self, from: r)
            )
        }
    }

    @discardableResult
    func autoregister<S, A, B, C, D>(_ initializer: @escaping (A, B, C, D) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r),
                resolved(B.self, from: r),
                resolved(C.self, from: r),
                resolved(D.self, from: r)
            )
        }
    }

    @discardableResult
    func autoregister<S, A, B, C, D, E>(_ initializer: @escaping (A, B, C, D, E) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r),
                resolved(B.self, from: r),
                resolved(C.self, from: r),
                resolved(D.self, from: r),
                resolved(E.self, from: r)
            )
        }
    }

    @discardableResult
    func autoregister<S, A, B, C, D, E, F>(_ initializer: @escaping (A, B, C, D, E, F) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r),
                resolved(B.self, from: r),
                resolved(C.self, from: r),
                resolved(D.self, from: r),
                resolved(E.self, from: r),
                resolved(F.self, from: r)
            )
        }
    }

    @discardableResult
    func autoregister<S, A, B, C, D, E, F, G>(_ initializer: @escaping (A, B, C, D, E, F, G) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r),
                resolved(B.self, from: r),
                resolved(C.self, from: r),
                resolved(D.self, from: r),
                resolved(E.self, from: r),
                resolved(F.self, from: r),
                resolved(G.self, from: r)
            )
        }
    }

    @discardableResult
    func autoregister<S, A, B, C, D, E, F, G, H>(_ initializer: @escaping (A, B, C, D, E, F, G, H) -> S) -> ServiceEntry<S> {
        register(S.self) { r in
            initializer(
                resolved(A.self, from: r),
                resolved(B.self, from: r),
                resolved(C.self, from: r),
                resolved(D.self, from: r),
                resolved(E.self, from: r),
                resolved(F.self, from: r),
                resolved(G.self, from: r),
                resolved(H.self, from: r)
            )
        }
    }
}
