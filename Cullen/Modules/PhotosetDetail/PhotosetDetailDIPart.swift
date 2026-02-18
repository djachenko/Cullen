//
//  PhotosetDetailDIPart.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import DITranquillity

final class PhotosetDetailDIPart: DIPart {
    static func load(container: DIContainer) {
        container.register(PhotosetDetailView.init) { arg($0) }
    }
}
