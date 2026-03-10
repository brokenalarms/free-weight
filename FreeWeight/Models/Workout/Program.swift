import Foundation

/// A training program is a named rotation of workout templates with a progression philosophy.
///
/// Example: GZCLP with 4 templates rotating A/B/A/B pattern:
///   Program(name: "GZCLP", rotation: [upperPower, lowerPower, upperHyper, lowerHyper], ...)
///
/// The rotation auto-advances: after completing one template, the next session
/// serves up the next template in the list, wrapping around.
struct Program: Identifiable, Codable {
    var id = UUID()
    var name: String                            // "GZCLP", "PPL", "5/3/1"
    var rotation: [WorkoutTemplate] = []        // Ordered list of templates in the cycle
    var progression: ProgressionRule = ProgressionRule()

    /// Index into rotation for the next workout (persisted)
    var currentRotationIndex: Int = 0

    /// How many completed sessions total (drives week calculation for progression)
    var completedSessions: Int = 0

    /// The next workout template in the rotation
    var nextTemplate: WorkoutTemplate? {
        guard !rotation.isEmpty else { return nil }
        return rotation[currentRotationIndex % rotation.count]
    }

    /// Current week number in the progression cycle (0-based)
    var currentWeekInCycle: Int {
        guard !rotation.isEmpty else { return 0 }
        let sessionsPerWeek = rotation.count  // e.g., 4 templates = 4 sessions per rotation
        let weekNumber = completedSessions / sessionsPerWeek
        return weekNumber % progression.cycleLength
    }

    /// Apply progression to a base weight for the current cycle position
    func adjustedWeight(base: Double) -> Double {
        let multiplier = progression.multiplier(forWeekInCycle: currentWeekInCycle)
        // Round to nearest 2.5 kg
        return (base * multiplier / 2.5).rounded() * 2.5
    }

    /// Advance to next template after completing a session
    mutating func advanceRotation() {
        completedSessions += 1
        currentRotationIndex = completedSessions % rotation.count
    }
}
