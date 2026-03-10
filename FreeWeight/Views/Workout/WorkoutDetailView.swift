import SwiftUI

/// Full workout log detail, shown when tapping the overlay chip on the timeline.
struct WorkoutDetailView: View {
    let log: WorkoutLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.templateName)
                        .font(.largeTitle.bold())
                    Text(log.programName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Label(
                            log.date.formatted(.dateTime.month(.wide).day().year()),
                            systemImage: "calendar"
                        )
                        if let duration = log.durationSeconds {
                            Label(formatDuration(duration), systemImage: "clock")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)

                // Exercises
                ForEach(log.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.headline)

                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { idx, set in
                            HStack {
                                Text("Set \(idx + 1)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Spacer()
                                Text(formatWeight(set.weight))
                                    .font(.subheadline.monospacedDigit())
                                Text("kg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("×")
                                    .foregroundStyle(.tertiary)
                                Text("\(set.reps)")
                                    .font(.subheadline.monospacedDigit())

                                Image(systemName: set.completed ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(set.completed ? .green : .red)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                if !log.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.headline)
                        Text(log.notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        if m < 60 { return "\(m) min" }
        let h = m / 60
        return "\(h)h \(m % 60)m"
    }
}
