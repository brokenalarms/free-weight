import SwiftUI

struct TimelineScrubber: View {
    let days: [TimelineDay]
    @Binding var selectedIndex: Int
    let scopedURL: URL?

    @State private var scrollPosition: Int?

    private let thumbnailWidth: CGFloat = 52
    private let thumbnailHeight: CGFloat = 70
    private let spacing: CGFloat = 4

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    scrubberTile(day: day, index: index)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                    index == selectedIndex ? .white : .clear,
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(index == selectedIndex ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.12), value: selectedIndex)
                        .id(index)
                        .onTapGesture {
                            selectedIndex = index
                        }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition)
        .onChange(of: scrollPosition) { _, newValue in
            if let newValue {
                selectedIndex = newValue
            }
        }
        .onChange(of: selectedIndex) { _, newValue in
            withAnimation(.easeInOut(duration: 0.15)) {
                scrollPosition = newValue
            }
        }
        .contentMargins(
            .horizontal,
            UIScreen.main.bounds.width / 2 - thumbnailWidth / 2
        )
        .sensoryFeedback(.selection, trigger: selectedIndex)
    }

    @ViewBuilder
    private func scrubberTile(day: TimelineDay, index: Int) -> some View {
        if let photoURL = day.primaryPhoto, let url = scopedURL {
            ZStack(alignment: .bottomTrailing) {
                ThumbnailView(
                    url: photoURL,
                    targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight),
                    scopedURL: url
                )

                // Green dot on photo days that also have a workout
                if day.hasWorkout {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .padding(3)
                }
            }
        } else {
            // Workout-only day — icon tile
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial)

                VStack(spacing: 2) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(day.date, format: .dateTime.day())
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
