//
//  FakeDecisionsRepository.swift
//  CullenTests
//

import Foundation
@testable import Cullen


final class FakeDecisionsRepository: DecisionsRepository {
    private(set) var saves: [(photosetId: PhotosetId, decisions: [PhotoId: Decision])] = []

    var stored: [PhotosetId: [PhotoId: Decision]]

    init(stored: [PhotosetId: [PhotoId: Decision]] = [:]) {
        self.stored = stored
    }

    func load(for photosetId: PhotosetId) async throws -> [PhotoId: Decision] {
        stored[photosetId] ?? [:]
    }

    func save(decisions: [PhotoId: Decision], for photosetId: PhotosetId) async throws {
        saves.append((photosetId, decisions))
        stored[photosetId] = decisions
    }
}
