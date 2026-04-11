//
//  DecisionsExport.swift
//  Cullen
//
//  Created by justin on 22/3/26.
//

import SwiftUI
import UniformTypeIdentifiers


struct DecisionsExport {
    let filename: String
    let dataProvider: () async throws -> Data
}

extension DecisionsExport: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in
            try await export.dataProvider()
        }
        .suggestedFileName { export in
            export.filename
        }
    }
}
