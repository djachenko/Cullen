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

        self.icon = switch option {
            case .recent:
                "clock"
            case .name:
                "textformat.abc"
            case .progress:
                "chart.bar.fill"
            case .photoCount:
                "photo.stack"
            case .lastOpened:
                "eye"
        }
    }
}
