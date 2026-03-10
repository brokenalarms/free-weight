import Foundation

/// How the program responds when you fail to hit target reps.
enum FailureStrategy: String, Codable, Hashable, CaseIterable, Identifiable {
    /// Retry same weight/reps next session. After `maxRetries`, deload.
    /// Classic linear progression (StrongLifts, Starting Strength).
    case retrySameWeight

    /// Keep weight, drop rep target (e.g., 5→3→1). On success at lower reps, bump weight.
    /// GZCLP T1 style.
    case dropReps

    /// Keep reps, drop weight by deloadPercent. Build back up.
    /// Standard percentage deload.
    case dropWeight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .retrySameWeight: "Retry same weight"
        case .dropReps: "Drop reps, keep weight"
        case .dropWeight: "Drop weight, keep reps"
        }
    }

    var description: String {
        switch self {
        case .retrySameWeight: "Try the same weight again. Deload after repeated failures."
        case .dropReps: "Lower the rep target but keep the weight. Progress when you hit the lower target."
        case .dropWeight: "Reduce the weight and work back up at the same rep target."
        }
    }
}

/// Defines how a program auto-progresses weights based on performance.
struct ProgressionRule: Codable, Hashable {
    /// Weight increase (kg) when all sets/reps are hit
    var weightIncrement: Double = 2.5

    /// What to do when you fail to complete all target reps
    var failureStrategy: FailureStrategy = .retrySameWeight

    /// How many consecutive failures before auto-deload kicks in
    var maxRetries: Int = 2

    /// Percentage to reduce weight on deload
    var deloadPercent: Double = 10.0

    /// For .dropReps strategy: the rep tiers to cycle through
    /// e.g., [5, 3, 1] means try 5 reps, if fail drop to 3, if fail drop to 1
    var repTiers: [Int] = [5, 3, 1]

    /// Scheduled deload: every N weeks, take a deload week (0 = never)
    var deloadEveryNWeeks: Int = 4

    /// User-friendly description
    var summary: String {
        var parts: [String] = []
        parts.append("+\(formatKg(weightIncrement)) kg on success")
        parts.append("on fail: \(failureStrategy.label.lowercased())")
        if deloadEveryNWeeks > 0 {
            parts.append("deload every \(deloadEveryNWeeks) weeks")
        }
        return parts.joined(separator: ", ")
    }

    private func formatKg(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}

/// The computed next target for an exercise based on past performance.
struct ExerciseTarget {
    let weight: Double
    let reps: Int
    let sets: Int
    let isDeload: Bool

    /// Format: "4×5 @ 82.5 kg" for strength, "3×12" for calisthenics, "3×30s" for mobility
    var display: String {
        display(for: .strength, durationSeconds: 0)
    }

    func display(for category: ExerciseCategory, durationSeconds: Int = 0) -> String {
        switch category {
        case .strength:
            return "\(sets)×\(reps) @ \(formatWeight(weight)) kg"
        case .calisthenics:
            return "\(sets)×\(reps)"
        case .mobility:
            if durationSeconds > 0 {
                return "\(sets)×\(durationSeconds)s"
            }
            return "\(sets) sets"
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
