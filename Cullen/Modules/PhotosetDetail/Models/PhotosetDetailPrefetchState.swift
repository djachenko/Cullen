//
//  PhotosetDetailPrefetchState.swift
//  Cullen
//
//  Created by justin on 11/4/26.
//


enum PhotosetDetailPrefetchState: Equatable {
    case notCached
    case partial
    case prefetching(progress: Double)
    case full
}