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
    let data: Data
}

extension DecisionsExport: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in
            export.data
        }
        .suggestedFileName { export in
            export.filename
        }
    }
}
