import Foundation

/// A single day on the unified timeline.
/// Can contain a progress photo, a workout log, or both.
struct TimelineDay: Identifiable, Comparable {
    let date: Date
    var photoEntry: ProgressEntry?
    var workoutLog: WorkoutLog?

    var id: Date { date }

    var hasPhoto: Bool { photoEntry != nil }
    var hasWorkout: Bool { workoutLog != nil }

    var primaryPhoto: URL? { photoEntry?.primaryPhoto }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date < rhs.date
    }

    /// Merge photo entries and workout logs into a unified sorted timeline.
    static func merge(
        photos: [ProgressEntry],
        workouts: [Date: WorkoutLog]
    ) -> [TimelineDay] {
        var daysByDate: [Date: TimelineDay] = [:]

        for entry in photos {
            let key = Calendar.current.startOfDay(for: entry.date)
            daysByDate[key, default: TimelineDay(date: key)].photoEntry = entry
        }

        for (date, log) in workouts {
            let key = Calendar.current.startOfDay(for: date)
            daysByDate[key, default: TimelineDay(date: key)].workoutLog = log
        }

        return daysByDate.values.sorted()
    }
}
