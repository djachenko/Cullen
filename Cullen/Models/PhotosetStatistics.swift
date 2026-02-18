//
//  PhotosetStatistics.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//


struct PhotosetStatistics {
    let totalSets: Int
    let totalPhotos: Int
    let completedSets: Int
    let pendingSyncCount: Int
    
    var completionRate: Double {
        guard totalSets > 0 else { return 0 }

        return Double(completedSets) / Double(totalSets)
    }
}
