import SwiftUI

/// Frosted glass chip overlaid at the bottom-center of the timeline photo.
/// Shows a one-line workout summary for that day. Tappable to open full log.
///
///   ┌───────────────────┐
///   │ Pull · DL 140×5   │
///   └───────────────────┘
struct WorkoutOverlayChip: View {
    let log: WorkoutLog
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption2)
                Text(log.summary)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
