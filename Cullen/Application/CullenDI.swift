//
//  CullenDI.swift
//  Cullen
//
//  Created by justin on 18/2/26.
//

import DITranquillity

final class CullenDI {
    static let container = {
        DISetting.Log.level = .info

        let container = DIContainer()
        container.append(part: RepositoriesDIPart.self)
        container.append(part: UseCasesDIPart.self)
        container.append(part: PhotosetFeedDIPart.self)
        container.append(part: PhotosetDetailDIPart.self)
        container.append(part: AppDIPart.self)

        container.initializeSingletonObjects()

//        if !container.makeGraph().checkIsValid(checkGraphCycles: true) {
//            assertionFailure("Failed to build valid dependency graph")
//        }

        return container
    }()
}
