//
//  MultiSegmentPickerView.swift
//  Cullen
//

import SwiftUI


struct MultiSegmentPickerView: View {
    private enum Layout {
        static let cornerRadius: CGFloat = 7
        static let segmentCornerRadius: CGFloat = 4
        static let spacing: CGFloat = 4
        static let inset: CGFloat = 3
        static let segmentPadding: CGFloat = 6
        static let fontSize: CGFloat = 13
    }

    let viewModel: MultiSegmentPickerViewModel

    var body: some View {
        HStack(spacing: Layout.spacing) {
            ForEach(viewModel.segments) { segment in
                segmentButton(segment)
            }
        }
        .padding(Layout.inset)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: Layout.cornerRadius))
    }
}

private extension MultiSegmentPickerView {
    func segmentButton(_ segment: SegmentViewModel) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                segment.onTap()
            }
        } label: {
            segmentLabel(segment)
        }
        .buttonStyle(.plain)
    }

    func segmentLabel(_ segment: SegmentViewModel) -> some View {
        let color: Color = if segment.isSelected {
            segment.color
        } else {
            .secondary
        }

        return Label(segment.title, systemImage: segment.icon)
            .font(.system(size: Layout.fontSize, weight: .medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Layout.segmentPadding)
            .background {
                if segment.isSelected {
                    selectionBackground
                }
            }
    }

    var selectionBackground: some View {
        RoundedRectangle(cornerRadius: Layout.segmentCornerRadius)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    @Previewable @State var selected: Set<String> = ["Alpha"]

    let segments = [("Alpha", "circle.fill", Color.green),
                    ("Beta", "square.fill", Color.orange),
                    ("Gamma", "triangle.fill", Color.blue)]

    MultiSegmentPickerView(
        viewModel: MultiSegmentPickerViewModel(
            segments: segments.map { title, icon, color in
                SegmentViewModel(
                    title: title,
                    icon: icon,
                    color: color,
                    isSelected: selected.contains(title),
                    onTap: { selected.formSymmetricDifference([title]) }
                )
            }
        )
    )
    .padding(.horizontal, 16)
}
