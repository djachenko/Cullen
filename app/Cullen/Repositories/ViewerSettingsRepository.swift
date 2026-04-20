//
//  ViewerSettingsRepository.swift
//  Cullen
//

import Foundation


protocol ViewerSettingsRepository {
    func load(for photosetId: PhotosetId) -> ViewerSettings
    func save(_ settings: ViewerSettings, for photosetId: PhotosetId)
}
