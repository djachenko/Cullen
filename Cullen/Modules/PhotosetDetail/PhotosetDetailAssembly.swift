//
//  PhotosetDetailAssembly.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import Swinject
import SwinjectAutoregistration


final class PhotosetDetailAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(PhotosetDetailView.init)

        container.autoregister(PhotosetDetailViewModel.init)
            .inObjectScope(.weak)
    }
}
