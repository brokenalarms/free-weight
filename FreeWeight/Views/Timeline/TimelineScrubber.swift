import SwiftUI

struct TimelineScrubber: View {
    let entries: [ProgressEntry]
    @Binding var selectedIndex: Int
    let scopedURL: URL

    @State private var scrollPosition: Int?

    private let thumbnailWidth: CGFloat = 52
    private let thumbnailHeight: CGFloat = 70
    private let spacing: CGFloat = 4

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    ThumbnailView(
                        url: entry.primaryPhoto,
                        targetSize: CGSize(width: thumbnailWidth, height: thumbnailHeight),
                        scopedURL: scopedURL
                    )
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
}
