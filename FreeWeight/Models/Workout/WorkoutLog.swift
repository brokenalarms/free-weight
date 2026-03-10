import Foundation

/// A completed workout session, persisted to the user's folder as JSON.
struct WorkoutLog: Identifiable, Codable {
    var id = UUID()
    var date: Date                              // Calendar date (matches photo dates)
    var programName: String                     // Snapshot of program name at time of logging
    var templateName: String                    // Snapshot of template name
    var exercises: [LoggedExercise] = []
    var durationSeconds: Int?                   // Optional: how long the session took
    var notes: String = ""

    /// A single exercise as actually performed
    struct LoggedExercise: Identifiable, Codable {
        var id = UUID()
        var name: String
        var sets: [LoggedSet] = []
    }

    struct LoggedSet: Identifiable, Codable {
        var id = UUID()
        var reps: Int
        var weight: Double                      // Actual weight used (kg)
        var completed: Bool = true              // Did they finish the set?
    }
}

extension WorkoutLog {
    /// One-line summary for the timeline overlay: "Pull · DL 140×5"
    var summary: String {
        var parts = [templateName]
        if let topLift = exercises.first(where: { !$0.sets.isEmpty }),
           let heaviestSet = topLift.sets.max(by: { $0.weight < $1.weight }) {
            let name = abbreviate(topLift.name)
            let w = formatWeight(heaviestSet.weight)
            parts.append("\(name) \(w)×\(heaviestSet.reps)")
        }
        return parts.joined(separator: " · ")
    }

    private func abbreviate(_ name: String) -> String {
        let abbreviations: [String: String] = [
            "Deadlift": "DL",
            "Romanian Deadlift": "RDL",
            "Bench Press": "Bench",
            "Overhead Press": "OHP",
            "Barbell Row": "Row",
            "Squat": "Squat",
            "Front Squat": "FS",
            "Pull Up": "Pull-up",
            "Lat Pulldown": "Lat PD",
        ]
        return abbreviations[name] ?? String(name.prefix(8))
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
