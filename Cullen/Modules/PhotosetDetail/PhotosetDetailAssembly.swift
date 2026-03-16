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
        container.register(PhotosetDetailView.self) { (resolver, photosetInfo: PhotosetInfo) in
            PhotosetDetailView(
                viewModel: resolver ~> (PhotosetDetailViewModel.self, argument: photosetInfo)
            )
        }

        container.autoregister(
            PhotosetDetailViewModel.self,
            argument: PhotosetInfo.self,
            initializer: PhotosetDetailViewModel.init
        )
        .inObjectScope(.weak)
    }
}
