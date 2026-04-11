//
//  PhotoViewerAssembly.swift
//  Cullen
//
//  Created by justin on 22/2/26.
//

import Swinject
import SwinjectAutoregistration


final class PhotoViewerAssembly: Assembly {
    func assemble(container: Container) {
        //        container.autoregister(PhotoViewerView.self, initializer: PhotoViewerView.init)
        container.register(PhotoViewerView.self) { (resover, photos: [Photo], startIndex: Int, photosetId: PhotosetId) in
            PhotoViewerView(
                viewModel: resover ~> (PhotoViewerViewModel.self, arguments: (photos, startIndex, photosetId))
            )
        }

        container.autoregister(
            PhotoViewerViewModel.self,
            arguments:
            [Photo].self,
            Int.self,
            PhotosetId.self,
            initializer: PhotoViewerViewModel.init
        )

        container.autoregister(SwipeGestureHandler.self, initializer: SwipeGestureHandler.init)
    }
}
