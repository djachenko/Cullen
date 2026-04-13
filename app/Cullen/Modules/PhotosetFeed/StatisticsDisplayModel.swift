//
//  StatisticsDisplayModel.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//


struct StatisticsDisplayModel {
    let totalSetsText: String
    let totalPhotosText: String
    let syncingCountText: String
    
    init(from statistics: PhotosetStatistics) {
        self.totalSetsText = "\(statistics.totalSets)"
        self.totalPhotosText = "\(statistics.totalPhotos)"
        self.syncingCountText = "\(statistics.pendingSyncCount)"
    }
}