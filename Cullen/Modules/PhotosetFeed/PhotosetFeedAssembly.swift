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
            .inObjectScope(.weak)

        container.register(PhotosetCardView.self) { (resolver, id: PhotosetId) in
            PhotosetCardView(
                viewModel: resolver ~> (PhotosetCardViewModel.self, argument: id)
            )
        }

        container.autoregister(
            PhotosetCardViewModel.self,
            argument: PhotosetId.self,
            initializer: PhotosetCardViewModel.init
        )
//        .inObjectScope(.weak)
    }
}
