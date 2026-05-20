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
        container.autoregister(SortPhotosetsUseCase.self, initializer: SortPhotosetsUseCaseImpl.init)
        container.autoregister(RecordLastOpenedUseCase.self, initializer: RecordLastOpenedUseCaseImpl.init)
        container.autoregister(FetchPhotosetUseCase.self, initializer: FetchPhotosetUseCaseImpl.init)
        container.autoregister(GetPhotosetStatisticsUseCase.self, initializer: GetPhotosetStatisticsUseCaseImpl.init)
        container.autoregister(FetchPhotosUseCase.self, initializer: FetchPhotosUseCaseImpl.init)
        container.autoregister(ExportDecisionsUseCase.self, initializer: ExportDecisionsUseCaseImpl.init)
        container.autoregister(CacheUseCase.self, initializer: CacheUseCaseImpl.init)
        container.autoregister(DecisionsStatsUseCase.self, initializer: DecisionsStatsUseCaseImpl.init)

        container.autoregister(DecisionsUseCaseImpl.init)
            .inObjectScope(.container) // shared state: decisions cache is shared across screens
            .implements(SaveDecisionUseCase.self)
            .implements(LoadDecisionsUseCase.self)
    }
}
