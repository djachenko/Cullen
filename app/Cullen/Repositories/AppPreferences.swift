//
//  AppPreferences.swift
//  Cullen
//

final class AppPreferences {
    @Preference(key: "cullen.feedSort.option", initialValue: PhotosetSortOption.recent)
    var sortOption: PhotosetSortOption

    @Preference(key: "cullen.feedSort.direction", initialValue: SortDirection.descending)
    var sortDirection: SortDirection
}
