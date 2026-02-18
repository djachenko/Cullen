//
//  Photo.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Foundation


struct Photo: Identifiable, Hashable {
    let id: UUID
    let fileName: String
    let localPath: URL?
    let remotePath: String
    var decision: Decision
    var syncStatus: SyncStatus
    let modifiedAt: Date
    let photoSetId: UUID
    
    var needsSync: Bool {
        syncStatus == .pending
    }
}
