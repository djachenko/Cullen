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


// FIFO без удаления из середины: снятые и переприоритезированные URL остаются
// лежать мертвецами, отсеивает их потребитель по своему словарю. Поэтому здесь
// только две операции — положить и взять следующий.
struct PriorityQueue {
    // Инвариант: пустых бакетов не бывает, иначе keys.max() соврёт.
    private var buckets: [SyncPriority: Deque<URL>] = [:]

    var isEmpty: Bool {
        buckets.isEmpty
    }

    mutating func enqueue(_ url: URL, priority: SyncPriority) {
        buckets[priority, default: []].append(url)
    }

    // Приоритет возвращается вместе с URL: по нему потребитель отличает живую
    // запись от мертвеца, оставшегося в старом бакете после переприоритизации.
    mutating func dequeue() -> (url: URL, priority: SyncPriority)? {
        guard let priority = buckets.keys.max(),
              let url = buckets[priority]?.popFirst() else {
            return nil
        }

        if buckets[priority]?.isEmpty == true {
            buckets[priority] = nil
        }

        return (url, priority)
    }
}
