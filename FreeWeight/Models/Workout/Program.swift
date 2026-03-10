import Foundation

/// A training program is a named rotation of workout templates with a progression philosophy.
///
/// The rotation auto-advances: after completing one template, the next session
/// serves up the next template in the list, wrapping around.
///
/// Progression is performance-based, not time-based:
/// - Hit all target sets/reps → increase weight
/// - Miss reps → strategy depends on failureStrategy (retry, drop reps, drop weight)
struct Program: Identifiable, Codable {
    var id = UUID()
    var name: String                            // "GZCLP", "PPL", "5/3/1"
    var rotation: [WorkoutTemplate] = []        // Ordered list of templates in the cycle
    var progression: ProgressionRule = ProgressionRule()

    /// Index into rotation for the next workout (persisted)
    var currentRotationIndex: Int = 0

    /// How many completed sessions total
    var completedSessions: Int = 0

    /// The next workout template in the rotation
    var nextTemplate: WorkoutTemplate? {
        guard !rotation.isEmpty else { return nil }
        return rotation[currentRotationIndex % rotation.count]
    }

    /// Advance to next template after completing a session
    mutating func advanceRotation() {
        completedSessions += 1
        currentRotationIndex = completedSessions % rotation.count
    }
}
