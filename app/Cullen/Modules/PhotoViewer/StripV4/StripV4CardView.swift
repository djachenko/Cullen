private struct StripV4CardView: View {
    let photo: Photo
    let decision: Decision
    let width: CGFloat
    let height: CGFloat
    let isActive: Bool
    let onSwipe: (SwipeDirection) -> Void

    @State private var dragOffset: CGFloat = 0

    private enum Layout {
        static let swipeThreshold: CGFloat = 70
        static let flyOffDistance: CGFloat = 500
        static let rotationFactor: Double = 0.04
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CullenImage(photo.url)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()

            DecisionBadge(decision: decision)
                .size(22)
                .padding(16)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(isActive ? 0.24 : 0.12), radius: 18, x: 0, y: 10)
        .offset(x: dragOffset)
        .rotationEffect(.degrees(Double(dragOffset) * Layout.rotationFactor), anchor: .bottom)
        .onHorizontalDrag(
            onChanged: { x in
                dragOffset = x
            },
            onEnded: { translation, velocity in
                let projected = translation + velocity * 0.1

                if abs(projected) > Layout.swipeThreshold {
                    let direction: SwipeDirection = if projected > 0 {
                        .right
                    } else {
                        .left
                    }

                    didSwipe(direction: direction)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
            }
        )
    }

    private func didSwipe(direction: SwipeDirection) {
        let targetX: CGFloat = if direction == .right {
            Layout.flyOffDistance
        } else {
            -Layout.flyOffDistance
        }

        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = targetX
        }

        onSwipe(direction)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            dragOffset = 0
        }
    }
}