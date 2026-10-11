//
//  PriorityQueue.swift
//  Cullen
//
//  Created by justin on 4/8/26.
//

import DequeModule
import Foundation


enum SyncPriority: Int, Comparable, CaseIterable {
    case low
    case normal
    case high

    static func < (lhs: SyncPriority, rhs: SyncPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}


// Each URL is queued at most once. Re-prioritizing or removing doesn't dig it out
// of its bucket: the old entry stays behind and dequeue() skips it, because only
// the entry matching `priorities` is live.
struct PriorityQueue {
    private var buckets: [SyncPriority: Deque<URL>] = [:]
    private var priorities: [URL: SyncPriority] = [:]

    mutating func enqueue(_ url: URL, priority: SyncPriority) {
        guard priorities[url] != priority else {
            return
        }

        priorities[url] = priority
        buckets[priority, default: []].append(url)
    }

    mutating func remove(_ url: URL) {
        priorities[url] = nil
    }

    mutating func dequeue() -> URL? {
        for priority in SyncPriority.allCases.reversed() {
            while let url = buckets[priority]?.popFirst() {
                guard priorities[url] == priority else {
                    continue
                }

                priorities[url] = nil

                return url
            }
        }

        return nil
    }
}
