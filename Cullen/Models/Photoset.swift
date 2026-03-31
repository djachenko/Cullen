//
//  Photoset.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation


struct Photoset: Identifiable, Hashable {
    let id: PhotosetId
    let name: String
    var syncStatus: SyncStatus
    let coverImageURL: URL?
    let photosCount: Int
    let photos: [Photo]
}
