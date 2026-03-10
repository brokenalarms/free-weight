import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64))
                .foregroundStyle(.accent)

            Text("FreeWeight")
                .font(.largeTitle.bold())

            Text("Track your gym progress with photos.\nYou own your data — pick a folder to store your photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button("Choose Folder") { showPicker = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Text("Photos are saved as regular files you can browse anytime.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
        }
        .sheet(isPresented: $showPicker) {
            FolderPickerRepresentable { url in
                try? FolderBookmarkManager.saveBookmark(for: url)
                appState.rootFolderURL = url
                Task { await appState.refreshTimeline() }
            }
        }
    }
}
