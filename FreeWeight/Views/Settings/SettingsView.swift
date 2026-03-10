import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showFolderPicker = false

    var body: some View {
        NavigationStack {
            List {
                Section("Storage") {
                    if let url = appState.rootFolderURL {
                        LabeledContent("Folder", value: url.lastPathComponent)
                    }
                    Button("Change Folder") { showFolderPicker = true }

                    LabeledContent(
                        "Photos",
                        value: "\(appState.timeline.entries.count) session\(appState.timeline.entries.count == 1 ? "" : "s")"
                    )
                }

                Section {
                    Link(destination: URL(string: "https://buymeacoffee.com/freeweight")!) {
                        Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
                    }
                }

                Section("About") {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    )
                    Text("FreeWeight is free. No accounts, no cloud, no upsells. Your photos stay on your device in a folder you control.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerRepresentable { url in
                    try? FolderBookmarkManager.saveBookmark(for: url)
                    appState.rootFolderURL = url
                    Task { await appState.refreshTimeline() }
                }
            }
        }
    }
}
