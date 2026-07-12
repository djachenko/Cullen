//
//  ExportLogsUseCase.swift
//  Cullen
//

import Foundation


protocol ExportLogsUseCase {
    func execute() async -> Data?
}

final class ExportLogsUseCaseImpl: ExportLogsUseCase {
    private let backend: LogBackend

    init(backend: LogBackend) {
        self.backend = backend
    }

    func execute() async -> Data? {
        await backend.export()
    }
}
