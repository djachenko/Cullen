//
//  SyncEventHub.swift
//  Cullen
//
//  Data - one broadcast for everything that resolves a URL. The cache reports
//  writes, the downloader reports give-ups; neither owns the other's channel,
//  and a consumer subscribes once instead of stitching two streams together.
//

import Foundation


enum SyncEvent {
    case cached(URL)
    case failed(URL) // exhausted retries — this URL won't be cached without a fresh request
}


protocol SyncEventPublisher: Sendable {
    func post(_ event: SyncEvent) async
}


protocol SyncEventSource: Sendable {
    func events() async -> AsyncStream<SyncEvent>
}


// AsyncStream has a single consumer, so subscribers are fanned out by hand.
actor SyncEventHub {
    private var subscribers: [UUID: AsyncStream<SyncEvent>.Continuation] = [:]
}


extension SyncEventHub: SyncEventPublisher {
    func post(_ event: SyncEvent) {
        subscribers.values.forEach {
            $0.yield(event)
        }
    }
}


extension SyncEventHub: SyncEventSource {
    func events() -> AsyncStream<SyncEvent> {
        let (stream, continuation) = AsyncStream<SyncEvent>.makeStream()
        let id = UUID()

        subscribers[id] = continuation

        continuation.onTermination = { [weak self] _ in
            Task {
                await self?.unsubscribe(id)
            }
        }

        return stream
    }
}


private extension SyncEventHub {
    func unsubscribe(_ id: UUID) {
        subscribers[id] = nil
    }
}
