//
//  SortPreferenceRepository.swift
//  Cullen
//

import Foundation


protocol SortPreferenceRepository {
    func load() -> (option: PhotosetSortOption, direction: SortDirection)?
    func save(option: PhotosetSortOption, direction: SortDirection)
}


final class UserDefaultsSortPreferenceRepository: SortPreferenceRepository {
    private static let optionKey = "cullen.feedSort.option"
    private static let directionKey = "cullen.feedSort.direction"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func load() -> (option: PhotosetSortOption, direction: SortDirection)? {
        guard
            let optionRaw = defaults.string(forKey: Self.optionKey),
            let option = PhotosetSortOption(rawValue: optionRaw),
            let directionRaw = defaults.string(forKey: Self.directionKey),
            let direction = SortDirection(rawValue: directionRaw)
        else {
            return nil
        }

        return (option, direction)
    }

    func save(option: PhotosetSortOption, direction: SortDirection) {
        defaults.set(option.rawValue, forKey: Self.optionKey)
        defaults.set(direction.rawValue, forKey: Self.directionKey)
    }
}
