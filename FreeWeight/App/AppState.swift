import SwiftUI

@Observable
final class AppState {
    var rootFolderURL: URL?
    var timeline = ProgressTimeline()
    var pinnedEntry: ProgressEntry?
    var pinnedAngle: PhotoAngle = .front
    var workoutStore: WorkoutStore?

    var hasFolder: Bool { rootFolderURL != nil }

    func refreshTimeline() async {
        guard let url = rootFolderURL else { return }
        let fm = ProgressFileManager(rootURL: url)
        if let entries = try? fm.loadTimeline() {
            timeline.entries = entries
        }
    }

    func setupWorkoutStore() {
        guard let url = rootFolderURL else { return }
        let store = WorkoutStore(rootURL: url)
        try? store.loadProgram()
        try? store.loadAllLogs()
        workoutStore = store
    }
}
