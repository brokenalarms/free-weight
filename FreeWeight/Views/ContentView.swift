import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasFolder {
            ProgressTimelineView()
        } else {
            OnboardingView()
        }
    }
}
