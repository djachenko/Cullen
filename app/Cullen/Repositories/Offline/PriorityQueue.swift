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
        let fresh = urls
            .distinct()
            .filter { priorities[$0] != priority }

        remove(fresh)

        fresh.forEach {
            priorities[$0] = priority
        }

        buckets[priority, default: []].append(contentsOf: fresh)
    }

    mutating func remove(_ urls: [URL]) {
        let distinctUrls = Set(urls)
        let prioritiesOfUrls = Set(distinctUrls.compactMap { priorities[$0] })

        prioritiesOfUrls.forEach {
            buckets[$0]?.removeAll { distinctUrls.contains($0) }
        }

        distinctUrls.forEach {
            priorities[$0] = nil
        }
    }

    func contains(_ url: URL) -> Bool {
        priorities[url] != nil
    }

    mutating func dequeue() -> (url: URL, priority: SyncPriority)? {
        guard let priority = SyncPriority.allCases.reversed().first(where: { buckets[$0]?.isEmpty == false }),
              let url = buckets[priority]?.popFirst() else {
            return nil
        }

        priorities[url] = nil

        return (url, priority)
    }
}


extension PriorityQueue {
    mutating func enqueue(_ url: URL, priority: SyncPriority) {
        enqueue([url], priority: priority)
    }
}
