//
//  PhotosetCacheState.swift
//  Cullen
//
//  Domain - cache state of a single photoset.
//


enum PhotosetCacheState: Equatable {
    case notCached
    case syncing(progress: Double)
    case synced
}
