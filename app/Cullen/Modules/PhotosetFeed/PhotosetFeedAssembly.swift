//
//  PhotosetFeedAssembly.swift
//  Cullen
//
//  Created by justin on 7/3/26.
//

import Swinject


final class PhotosetFeedAssembly: Assembly {
    func assemble(container: Container) {
        container.autoregister(PhotosetFeedView.init)
        container.autoregister(PhotosetFeedViewModel.init)
            .inObjectScope(.weak)

        container.autoregister(PhotosetCardView.init)
        container.autoregister(PhotosetCardViewModel.init)
    }
}
