//
//  AppDIPart.swift
//  Cullen
//
//  Created by justin on 19/2/26.
//

import DITranquillity

final class AppDIPart: DIPart {
    static func load(container: DIContainer) {
        container.register(AppCoordinator.init) { arg($0) }
            .lifetime(.perContainer(.weak))

        container.register(AppCoordinatorView.init)
    }
}
