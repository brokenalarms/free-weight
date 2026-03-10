import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasFolder {
            TabView {
                Tab("Workout", systemImage: "figure.strengthtraining.traditional") {
                    WorkoutLandingView()
                }
                Tab("Progress", systemImage: "photo.stack") {
                    ProgressTimelineView()
                }
            }
        } else {
            OnboardingView()
        }
    }
}
