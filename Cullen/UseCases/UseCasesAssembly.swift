//
//  UseCasesAssembly.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import Swinject
import SwinjectAutoregistration


final class UseCasesAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(FetchPhotosetsUseCase.self, initializer: FetchPhotosetsUseCaseImpl.init)
        container.autoregister(FetchPhotosetUseCase.self, initializer: FetchPhotosetUseCaseImpl.init)
        container.autoregister(FetchPhotosetInfoUseCase.self, initializer: FetchPhotosetInfoUseCaseImpl.init)
        container.autoregister(GetPhotosetStatisticsUseCase.self, initializer: GetPhotosetStatisticsUseCaseImpl.init)
        container.autoregister(FetchPhotosUseCase.self, initializer: FetchPhotosUseCaseImpl.init)

        container.autoregister(DecisionsUseCaseImpl.self, initializer: DecisionsUseCaseImpl.init)
            .inObjectScope(.container)
            .implements(SaveDecisionUseCase.self)
            .implements(LoadDecisionsUseCase.self)
    }
}
