import SwiftUI

@main
struct FreeWeightApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    if let url = FolderBookmarkManager.resolveBookmark() {
                        appState.rootFolderURL = url
                        await appState.refreshTimeline()
                    }
                }
        }
    }
}
