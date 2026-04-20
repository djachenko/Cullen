//
//  Preference.swift
//  Cullen
//

import Foundation


/// Property wrapper для хранения значений в `UserDefaults`.
///
/// > Warning: `initialValue` **не может быть `nil`**. Для опциональных значений
/// > используй инициализатор без `initialValue`, доступный для `Optional`-типов:
/// > ```swift
/// > @Preference(key: "someKey") var value: String?
/// > ```
@propertyWrapper struct Preference<Value> {
    var wrappedValue: Value {
        get { getBlock() }
        set { setBlock(newValue) }
    }

    private let getBlock: () -> Value
    private let setBlock: (Value) -> Void

    init(key: String, initialValue: Value, userDefaults: UserDefaults = .standard) {
        getBlock = {
            if let stored = userDefaults.object(forKey: key) as? Value {
                return stored
            }
            userDefaults.set(initialValue, forKey: key)
            return initialValue
        }
        setBlock = { newValue in
            userDefaults.set(newValue, forKey: key)
        }
    }
}

// MARK: - RawRepresentable

extension Preference where Value: RawRepresentable, Value.RawValue == String {
    init(key: String, initialValue: Value, userDefaults: UserDefaults = .standard) {
        getBlock = {
            guard let raw = userDefaults.string(forKey: key) else {
                userDefaults.set(initialValue.rawValue, forKey: key)
                return initialValue
            }
            return Value(rawValue: raw) ?? initialValue
        }
        setBlock = { newValue in
            userDefaults.set(newValue.rawValue, forKey: key)
        }
    }
}

extension Preference where Value: RawRepresentable, Value.RawValue == Int {
    init(key: String, initialValue: Value, userDefaults: UserDefaults = .standard) {
        getBlock = {
            guard userDefaults.object(forKey: key) != nil else {
                userDefaults.set(initialValue.rawValue, forKey: key)
                return initialValue
            }
            return Value(rawValue: userDefaults.integer(forKey: key)) ?? initialValue
        }
        setBlock = { newValue in
            userDefaults.set(newValue.rawValue, forKey: key)
        }
    }
}

// MARK: - Optional

extension Preference where Value: ExpressibleByNilLiteral {
    init(key: String, userDefaults: UserDefaults = .standard) where Value == Bool? {
        self.init(optionalType: Bool.self, key: key, userDefaults: userDefaults)
    }

    init(key: String, userDefaults: UserDefaults = .standard) where Value == Int? {
        self.init(optionalType: Int.self, key: key, userDefaults: userDefaults)
    }

    init(key: String, userDefaults: UserDefaults = .standard) where Value == Double? {
        self.init(optionalType: Double.self, key: key, userDefaults: userDefaults)
    }

    init(key: String, userDefaults: UserDefaults = .standard) where Value == String? {
        self.init(optionalType: String.self, key: key, userDefaults: userDefaults)
    }

    init(key: String, userDefaults: UserDefaults = .standard) where Value == Data? {
        self.init(optionalType: Data.self, key: key, userDefaults: userDefaults)
    }

    private init<T>(optionalType: T.Type, key: String, userDefaults: UserDefaults) {
        getBlock = {
            // swiftlint:disable:next redundant_nil_coalescing
            userDefaults.object(forKey: key) as? Value ?? nil
        }
        setBlock = { newValue in
            if let newValue = newValue as? T? {
                userDefaults.set(newValue, forKey: key)
            } else {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}
