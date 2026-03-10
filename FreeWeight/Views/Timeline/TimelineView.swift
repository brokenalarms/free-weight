import SwiftUI

struct ProgressTimelineView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedIndex: Int = 0
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var displayedAngle: PhotoAngle = .front
    @State private var showCompare = false

    private var entries: [ProgressEntry] { appState.timeline.entries }

    private var currentEntry: ProgressEntry? {
        guard entries.indices.contains(selectedIndex) else { return nil }
        return entries[selectedIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if entries.isEmpty {
                    emptyState
                } else {
                    timelineContent
                }
            }
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    pinButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCapture = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }
            }
            .fullScreenCover(isPresented: $showCapture) {
                CaptureView()
                    .environment(appState)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(appState)
            }
            .navigationDestination(isPresented: $showCompare) {
                if let pinned = appState.pinnedEntry,
                   let current = currentEntry,
                   pinned.date != current.date {
                    CompareView(
                        pinnedEntry: pinned,
                        compareEntry: current,
                        angle: appState.pinnedAngle,
                        scopedURL: appState.rootFolderURL ?? URL(fileURLWithPath: "/")
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Progress Photos Yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Take your first progress photo to start tracking.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showCapture = true
            } label: {
                Label("Take Photo", systemImage: "camera.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ViewBuilder
    private var timelineContent: some View {
        VStack(spacing: 0) {
            // Angle picker (only show if current entry has multiple angles)
            if let entry = currentEntry, entry.photos.count > 1 {
                Picker("Angle", selection: $displayedAngle) {
                    ForEach(PhotoAngle.allCases.filter { entry.photos[$0] != nil }) { angle in
                        Text(angle.label).tag(angle)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }

            // Main photo display
            if let rootURL = appState.rootFolderURL {
                ScopedPhotoView(
                    url: currentEntry?.photos[displayedAngle] ?? currentEntry?.primaryPhoto,
                    scopedURL: rootURL
                )
                .id(currentEntry?.date)
                .transition(.opacity.animation(.easeInOut(duration: 0.08)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Compare button when pinned
                if let pinned = appState.pinnedEntry,
                   let current = currentEntry,
                   pinned.date != current.date {
                    Button {
                        showCompare = true
                    } label: {
                        Label("Compare with pinned", systemImage: "arrow.left.and.right")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.bottom, 4)
                }

                // Date label
                if let entry = currentEntry {
                    Text(entry.date, format: .dateTime.month(.wide).day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }

                // Scrubber
                TimelineScrubber(
                    entries: entries,
                    selectedIndex: $selectedIndex,
                    scopedURL: rootURL
                )
                .frame(height: 80)
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private var pinButton: some View {
        if let current = currentEntry {
            Button {
                if appState.pinnedEntry?.date == current.date {
                    appState.pinnedEntry = nil
                } else {
                    appState.pinnedEntry = current
                    appState.pinnedAngle = displayedAngle
                }
            } label: {
                Image(systemName: appState.pinnedEntry?.date == current.date
                      ? "pin.slash.fill" : "pin")
            }
        }
    }
}
