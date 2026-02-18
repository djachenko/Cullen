//
//  RepositoriesDIPart.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import DITranquillity

final class RepositoriesDIPart: DIPart {
    static func load(container: DIContainer) {
        container.register(MockPhotosetsRepository.init)
            .as(PhotosetsRepository.self)
    }
}
