//
//  SyncBadgeViewModel.swift
//  Cullen
//
//  Created by justin on 14/2/26.
//

import SwiftUI


struct SyncBadgeViewModel: Hashable {
    let text: String
    let color: Color
    
    init(from status: SyncStatus) {
        switch status {
        case .synced:
            self.text = "Synced"
            self.color = .green
        case .pending:
            self.text = "Syncing..."
            self.color = .orange
        case .error:
            self.text = "Error"
            self.color = .red
        }
    }
}
