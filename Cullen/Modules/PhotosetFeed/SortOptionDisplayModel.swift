//
//  SortOptionDisplayModel.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//


struct SortOptionDisplayModel: Identifiable {
    let id: String
    let title: String
    let icon: String
    let option: PhotosetSortOption
    
    init(option: PhotosetSortOption) {
        self.id = option.rawValue
        self.title = option.rawValue
        self.option = option
        
        switch option {
        case .recent:
            self.icon = "clock"
        case .name:
            self.icon = "textformat.abc"
        case .progress:
            self.icon = "chart.bar.fill"
        case .photoCount:
            self.icon = "photo.stack"
        }
    }
}