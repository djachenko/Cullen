//
//  RecordLastOpenedUseCase.swift
//  Cullen
//

import Foundation


protocol RecordLastOpenedUseCase {
    func execute(id: PhotosetId) async
}


final class RecordLastOpenedUseCaseImpl: RecordLastOpenedUseCase {
    private let repository: LastOpenedRepository

    init(repository: LastOpenedRepository) {
        self.repository = repository
    }

    func execute(id: PhotosetId) async {
        await repository.record(id: id)
    }
}
