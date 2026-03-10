import SwiftUI

@Observable
final class AppState {
    var rootFolderURL: URL?
    var timeline = ProgressTimeline()
    var pinnedEntry: ProgressEntry?
    var pinnedAngle: PhotoAngle = .front
    let workoutStore = WorkoutStore()

    var hasFolder: Bool { rootFolderURL != nil }

    /// Unified timeline merging photos and workout logs by date.
    var timelineDays: [TimelineDay] {
        TimelineDay.merge(
            photos: timeline.entries,
            workouts: workoutStore.logs
        )
    }

    /// True if there's any content to show (photos or workouts)
    var hasTimelineContent: Bool {
        !timeline.entries.isEmpty || !workoutStore.logs.isEmpty
    }

    func refreshTimeline() async {
        guard let url = rootFolderURL else { return }
        let fm = ProgressFileManager(rootURL: url)
        if let entries = try? fm.loadTimeline() {
            timeline.entries = entries
        }
    }

    func loadWorkoutData() {
        try? workoutStore.loadProgram()
        try? workoutStore.loadAllLogs()
    }
}
