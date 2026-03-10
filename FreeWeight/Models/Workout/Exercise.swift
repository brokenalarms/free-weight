import Foundation

/// What kind of exercise this is — determines the logging UX and progression.
enum ExerciseCategory: String, Codable, Hashable, CaseIterable, Identifiable {
    /// Barbell/dumbbell — tracked by weight × reps. Auto-progresses.
    case strength

    /// Bodyweight — tracked by reps (or hold duration). No weight field needed.
    case calisthenics

    /// Stretches, foam rolling, etc. — just tick done per set. Duration-based.
    case mobility

    var id: String { rawValue }

    var label: String {
        switch self {
        case .strength: "Strength"
        case .calisthenics: "Calisthenics"
        case .mobility: "Mobility"
        }
    }

    var icon: String {
        switch self {
        case .strength: "dumbbell.fill"
        case .calisthenics: "figure.gymnastics"
        case .mobility: "figure.flexibility"
        }
    }
}

struct Exercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var category: ExerciseCategory = .strength
    var targetSets: Int
    var targetReps: Int
    var weight: Double              // kg — only relevant for .strength
    var durationSeconds: Int = 0    // hold/stretch duration — for .mobility
    var restSeconds: Int = 90
    var notes: String = ""

    /// Whether this exercise tracks weight
    var isWeighted: Bool { category == .strength }

    /// Whether this exercise is just "do it and tick done"
    var isTickOnly: Bool { category == .mobility }
}
