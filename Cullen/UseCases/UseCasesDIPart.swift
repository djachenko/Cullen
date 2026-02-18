//
//  UseCasesDIPart.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import DITranquillity

final class UseCasesDIPart: DIPart {
    static func load(container: DITranquillity.DIContainer) {
        container.register(FetchPhotosetsUseCase.init)
            .as(FetchPhotosetsUseCaseProtocol.self)

        container.register(GetPhotosetStatisticsUseCase.init)
            .as(GetPhotosetStatisticsUseCaseProtocol.self)
    }
}
