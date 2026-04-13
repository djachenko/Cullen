//
//  DecisionsRepository.swift
//  Cullen
//
//  Created by justin on 18/3/26.
//

import Foundation


protocol DecisionsRepository {
    func load(for photosetId: PhotosetId) async throws -> [PhotoId: Decision]
    func save(decisions: [PhotoId: Decision], for photosetId: PhotosetId) async throws
}
