import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            Tab("Workout", systemImage: "figure.strengthtraining.traditional") {
                WorkoutLandingView()
            }
            Tab("Progress", systemImage: "photo.stack") {
                if appState.hasFolder {
                    ProgressTimelineView()
                } else {
                    OnboardingView()
                }
            }
        }
    }
}
