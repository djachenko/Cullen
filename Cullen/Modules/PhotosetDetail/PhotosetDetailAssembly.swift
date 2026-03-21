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
        container.register(PhotosetDetailView.self) { (resolver, id: PhotosetId) in
            PhotosetDetailView(
                viewModel: resolver ~> (PhotosetDetailViewModel.self, argument: id)
            )
        }

        container.register(PhotosetDetailViewModel.self) { (resolver, id: PhotosetId) in
            PhotosetDetailViewModel(
                id: id,
                coordinator: resolver ~> Coordinator.self,
                fetchPhotosetUseCase: resolver ~> FetchPhotosetUseCase.self,
                fetchPhotosUseCase: resolver ~> FetchPhotosUseCase.self,
                loadDecisionsUseCase: resolver ~> LoadDecisionsUseCase.self
            )
        }
        .inObjectScope(.weak)
    }
}
