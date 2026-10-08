//
//  PhotoViewerAssembly.swift
//  Cullen
//
//  Created by justin on 22/2/26.
//

import Swinject


final class PhotoViewerAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(PhotoViewerView.init)
        container.autoregister(PhotoViewerViewModel.init)
        container.autoregister(SwipeGestureHandler.init)
        container.autoregister(UserDefaultsViewerSettingsRepository.init)
            .implements(ViewerSettingsRepository.self)
            .inObjectScope(.container)
    }
}
