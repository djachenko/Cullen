//
//  SyncStatus.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//


enum SyncStatus: String, Codable {
    case synced
    case pending
    case error
}

extension SyncStatus: CaseIterable {}
