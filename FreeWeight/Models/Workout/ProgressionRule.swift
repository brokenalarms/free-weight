import Foundation

/// Defines how a program auto-progresses weights.
///
/// Example: GZCLP style — load 2 weeks, deload 1 week
///   ProgressionRule(loadWeeks: 2, loadPercent: 5.0, deloadWeeks: 1, deloadPercent: 10.0)
///
/// Example: Linear — just add weight every session
///   ProgressionRule(loadWeeks: 1, loadPercent: 2.5, deloadWeeks: 0, deloadPercent: 0)
struct ProgressionRule: Codable, Hashable {
    /// Number of weeks to progressively load before deload
    var loadWeeks: Int = 2

    /// Percentage to increase weight each load week
    var loadPercent: Double = 5.0

    /// Number of deload weeks in the cycle
    var deloadWeeks: Int = 1

    /// Percentage to reduce from peak during deload
    var deloadPercent: Double = 10.0

    /// Total cycle length
    var cycleLength: Int { loadWeeks + deloadWeeks }

    /// Given the week number within a cycle (0-based), return the weight multiplier.
    /// Week 0..loadWeeks-1 = progressive load, loadWeeks..cycleLength-1 = deload
    func multiplier(forWeekInCycle week: Int) -> Double {
        let weekInCycle = week % cycleLength
        if weekInCycle < loadWeeks {
            // Progressive: base + (weekInCycle * loadPercent%)
            return 1.0 + (Double(weekInCycle) * loadPercent / 100.0)
        } else {
            // Deload: reduce from peak
            let peakMultiplier = 1.0 + (Double(loadWeeks - 1) * loadPercent / 100.0)
            return peakMultiplier * (1.0 - deloadPercent / 100.0)
        }
    }

    /// User-friendly description
    var summary: String {
        if deloadWeeks == 0 {
            return "+\(formatPercent(loadPercent))% weekly"
        }
        return "\(loadWeeks)w load +\(formatPercent(loadPercent))%, \(deloadWeeks)w deload -\(formatPercent(deloadPercent))%"
    }

    private func formatPercent(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
