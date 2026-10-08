//
//  MultiSegmentPickerViewModel.swift
//  Cullen
//

import SwiftUI


struct SegmentViewModel {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool

    let onTap: () -> Void
}

extension SegmentViewModel: Identifiable {
    var id: String { title }
}


struct MultiSegmentPickerViewModel {
    let segments: [SegmentViewModel]
}
