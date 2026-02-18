//
//  PhotosetFeedDIPart.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import DITranquillity

final class PhotosetFeedDIPart: DIPart {
    static func load(container: DIContainer) {
        container.register(PhotosetFeedView.init)
        container.register(PhotosetFeedViewModel.init)
    }
}
