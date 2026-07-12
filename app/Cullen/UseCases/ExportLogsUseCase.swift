//
//  ExportLogsUseCase.swift
//  Cullen
//

import Foundation


protocol ExportLogsUseCase {
    func execute() async -> URL?
}

final class ExportLogsUseCaseImpl: ExportLogsUseCase {
    private let backend: LogBackend

    init(backend: LogBackend) {
        self.backend = backend
    }

    func execute() async -> URL? {
        await backend.export()
    }
}
