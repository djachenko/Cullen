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
        container.autoregister(FetchPhotosetsUseCaseProtocol.self, initializer: FetchPhotosetsUseCase.init)
        container.autoregister(
            GetPhotosetStatisticsUseCaseProtocol.self,
            initializer: GetPhotosetStatisticsUseCase.init
        )
    }
}
