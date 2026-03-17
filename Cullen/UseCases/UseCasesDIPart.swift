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
        container.autoregister(FetchPhotosetInfoUseCase.self, initializer: FetchPhotosetInfoUseCaseImpl.init)
        container.autoregister(
            GetPhotosetStatisticsUseCase.self,
            initializer: GetPhotosetStatisticsUseCaseImpl.init
        )
        container.autoregister(FetchPhotosUseCase.self, initializer: FetchPhotosUseCaseImpl.init)
    }
}
