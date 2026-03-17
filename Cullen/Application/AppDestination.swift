//
//  AppDestination.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import Foundation


enum AppDestination: Hashable {
    case photosetFeed
    case photosetDetail(PhotosetInfo)
    case photoViewer(photos: [Photo], startIndex: Int)
}
