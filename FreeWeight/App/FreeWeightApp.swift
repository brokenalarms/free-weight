import SwiftUI

@main
struct FreeWeightApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    // Workout data lives in app Documents / iCloud — always load
                    appState.loadWorkoutData()

                    // Photos live in user-picked folder
                    if let url = FolderBookmarkManager.resolveBookmark() {
                        appState.rootFolderURL = url
                        await appState.refreshTimeline()
                    }
                }
        }
    }
}
