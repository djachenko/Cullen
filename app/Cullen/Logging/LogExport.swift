//
//  LogExport.swift
//  Cullen
//

import SwiftUI
import UniformTypeIdentifiers


struct LogExport {
    let filename: String
    let dataProvider: () async throws -> Data
}

extension LogExport: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .plainText) { export in
            try await export.dataProvider()
        }
        .suggestedFileName { $0.filename }
    }
}
