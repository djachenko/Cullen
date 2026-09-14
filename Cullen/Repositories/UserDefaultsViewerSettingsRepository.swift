//
//  UserDefaultsViewerSettingsRepository.swift
//  Cullen
//

import Foundation


final class UserDefaultsViewerSettingsRepository: ViewerSettingsRepository {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func load(for photosetId: PhotosetId) -> ViewerSettings {
        var preference = modePreference(for: photosetId)
        return ViewerSettings(mode: preference.wrappedValue)
    }

    func save(_ settings: ViewerSettings, for photosetId: PhotosetId) {
        var preference = modePreference(for: photosetId)
        preference.wrappedValue = settings.mode
    }
}

private extension UserDefaultsViewerSettingsRepository {
    func modePreference(for photosetId: PhotosetId) -> Preference<ViewerMode> {
        Preference(key: "viewerMode_\(photosetId)", initialValue: ViewerSettings.default.mode, userDefaults: userDefaults)
    }
}
