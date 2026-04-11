//
//  Photo.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation

typealias PhotoId = String

struct Photo: Identifiable, Hashable {
    let id: PhotoId
//    let fileName: String
    let url: URL?
//    let remotePath: String
    var decision: Decision
//    var syncStatus: SyncStatus
//    let modifiedAt: Date
//    let photosetId: PhotosetId
//    
//    var needsSync: Bool {
//        syncStatus == .pending
//    }
}
