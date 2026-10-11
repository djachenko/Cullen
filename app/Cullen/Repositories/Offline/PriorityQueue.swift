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


// Each URL sits in exactly one bucket; the latest priority wins, so a URL can
// be demoted as well as boosted. Moving and removing take one pass per bucket
// for the whole batch, dequeue stays O(1).
struct PriorityQueue {
    private var buckets: [SyncPriority: Deque<URL>] = [:]
    private var priorities: [URL: SyncPriority] = [:]

    mutating func enqueue(_ urls: [URL], priority: SyncPriority) {
        var seen = Set<URL>()
        let fresh = urls.filter { priorities[$0] != priority && seen.insert($0).inserted }

        remove(fresh)

        fresh.forEach {
            priorities[$0] = priority
        }

        buckets[priority, default: []].append(contentsOf: fresh)
    }

    mutating func remove(_ urls: [URL]) {
        let queued = Set(urls)

        for priority in Set(queued.compactMap { priorities[$0] }) {
            buckets[priority]?.removeAll { queued.contains($0) }
        }

        queued.forEach {
            priorities[$0] = nil
        }
    }

    mutating func dequeue() -> URL? {
        for priority in SyncPriority.allCases.reversed() {
            if let url = buckets[priority]?.popFirst() {
                priorities[url] = nil

                return url
            }
        }

        return nil
    }
}
