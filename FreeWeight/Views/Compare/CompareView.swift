import SwiftUI

struct CompareView: View {
    let pinnedEntry: ProgressEntry
    let compareEntry: ProgressEntry
    let angle: PhotoAngle
    let scopedURL: URL

    @State private var sliderPosition: CGFloat = 0.5
    @State private var mode: CompareMode = .sideBySide

    enum CompareMode: String, CaseIterable {
        case sideBySide = "Side by Side"
        case overlay = "Overlay"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(CompareMode.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            switch mode {
            case .sideBySide:
                sideBySideView
            case .overlay:
                overlayView
            }

            // Date labels
            HStack {
                dateLabel(pinnedEntry.date, prefix: "Pinned")
                Spacer()
                dateLabel(compareEntry.date, prefix: "Current")
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var sideBySideView: some View {
        HStack(spacing: 2) {
            ScopedPhotoView(
                url: pinnedEntry.photos[angle] ?? pinnedEntry.primaryPhoto,
                scopedURL: scopedURL
            )
            .clipShape(Rectangle())

            ScopedPhotoView(
                url: compareEntry.photos[angle] ?? compareEntry.primaryPhoto,
                scopedURL: scopedURL
            )
            .clipShape(Rectangle())
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var overlayView: some View {
        GeometryReader { geo in
            ZStack {
                // Pinned photo (underneath)
                ScopedPhotoView(
                    url: pinnedEntry.photos[angle] ?? pinnedEntry.primaryPhoto,
                    scopedURL: scopedURL
                )

                // Compare photo (on top, clipped by slider)
                ScopedPhotoView(
                    url: compareEntry.photos[angle] ?? compareEntry.primaryPhoto,
                    scopedURL: scopedURL
                )
                .clipShape(
                    HorizontalClipShape(xPosition: geo.size.width * sliderPosition)
                )

                // Slider handle
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .position(x: geo.size.width * sliderPosition, y: geo.size.height / 2)
                    .shadow(color: .black.opacity(0.5), radius: 2)

                // Drag handle circle
                Circle()
                    .fill(.white)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemName: "arrow.left.and.right")
                            .font(.caption2)
                            .foregroundStyle(.black)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .position(x: geo.size.width * sliderPosition, y: geo.size.height / 2)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        sliderPosition = min(max(value.location.x / geo.size.width, 0), 1)
                    }
            )
        }
        .frame(maxHeight: .infinity)
    }

    private func dateLabel(_ date: Date, prefix: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(prefix)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(date, format: .dateTime.month(.abbreviated).day().year())
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
}

/// Clips content to the right side of a given x position.
struct HorizontalClipShape: Shape {
    let xPosition: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(
            x: xPosition,
            y: rect.minY,
            width: rect.width - xPosition,
            height: rect.height
        ))
    }
}
