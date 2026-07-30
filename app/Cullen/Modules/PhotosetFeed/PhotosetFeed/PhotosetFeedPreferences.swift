//
//  PhotosetFeedPreferences.swift
//  Cullen
//
//  Created by justin on 31/7/26.
//


protocol PhotosetFeedPreferences: AnyObject {
    var sortOption: PhotosetSortOption { get set }
    var sortDirection: SortDirection { get set }
}