//
//  PhotosetSortOption.swift
//  Cullen
//
//  Created by justin on 25/3/26.
//


enum PhotosetSortOption: String, CaseIterable, Identifiable {
    case recent = "Recent"
    case name = "Name"
    case progress = "Progress"
    case photoCount = "Photos"
    
    var id: String { rawValue }
}
