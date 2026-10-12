//
//  WeakValueMap.swift
//  Cullen
//
//  Keyed by a runtime value, holding its values weakly.
//
//  Swinject can't express this: an object scope is stored on the service entry,
//  whose key carries the argument *type*, never the value — so a scope would
//  hand out one instance for every key. Registering per value under a `name`
//  would work, but leaves an entry behind for every key ever seen and mutates
//  the container mid-resolve. So the map lives next to the registration that
//  needs it, and callers just resolve the value they wanted.
//

import Foundation
import Synchronization


final class WeakValueMap<Key: Hashable, Value: AnyObject> {
    private final class Box {
        weak var value: Value?

        init(_ value: Value) {
            self.value = value
        }
    }

    // Not an actor: callers are Swinject factories, which are synchronous.
    private let storage = Mutex<[Key: Box]>([:])

    func value(for key: Key, make: () -> Value) -> Value {
        storage.withLock { storage in
            if let existing = storage[key]?.value {
                return existing
            }

            let value = make()
            storage[key] = Box(value)

            return value
        }
    }
}
