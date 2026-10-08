//
//  AppPreferences.swift
//  Cullen
//

final class AppPreferences {
    @Preference(key: "cullen.feedSort.option", initialValue: PhotosetSortOption.default)
    var sortOption: PhotosetSortOption

    @Preference(key: "cullen.feedSort.direction", initialValue: SortDirection.descending)
    var sortDirection: SortDirection

    @Preference(key: "cullen.signingExpiration.notificationIds", initialValue: [])
    var notificationIds: [String]
}

extension AppPreferences: PhotosetFeedPreferences {}
extension AppPreferences: SigningExpirationServicePreferences {}
