//
//  PhotosetFeedAssembly.swift
//  Cullen
//
//  Created by justin on 7/3/26.
//

import Swinject
import SwinjectAutoregistration


final class PhotosetFeedAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(PhotosetFeedView.self, initializer: PhotosetFeedView.init)
        container.autoregister(PhotosetFeedViewModel.self, initializer: PhotosetFeedViewModel.init)
    }
}
