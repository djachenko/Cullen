//
//  PhotosetInfo.swift
//  Cullen
//
//  Created by justin on 8/3/26.
//

import Foundation


struct PhotosetInfo {
    let id: PhotosetId
    let title: String
    let coverUrl: URL?

    let photosCount: Int
    let approvedCount: Int
    let rejectedCount: Int
}

extension PhotosetInfo: Hashable {}
