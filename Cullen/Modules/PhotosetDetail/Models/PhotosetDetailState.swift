//
//  PhotosetDetailState.swift
//  Cullen
//
//  Created by justin on 11/4/26.
//


typealias PhotosetDetailContent = [PhotoGridCellViewModel]

enum PhotosetDetailState {
    case initial
    case loading
    case content(PhotosetDetailContent)
    case error(message: String)

    var isLoading: Bool {
        switch self {
        case .initial, .loading:
            true
        case .content, .error:
            false
        }
    }
}
