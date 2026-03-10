import SwiftUI

struct ProgressTimelineView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedIndex: Int = 0
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var displayedAngle: PhotoAngle = .front
    @State private var showCompare = false
    @State private var showWorkoutDetail = false
    @State private var selectedWorkoutLog: WorkoutLog?

    private var days: [TimelineDay] { appState.timelineDays }

    private var currentDay: TimelineDay? {
        guard days.indices.contains(selectedIndex) else { return nil }
        return days[selectedIndex]
    }

    private var currentEntry: ProgressEntry? { currentDay?.photoEntry }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if !appState.hasTimelineContent {
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
            .navigationDestination(isPresented: $showWorkoutDetail) {
                if let log = selectedWorkoutLog {
                    WorkoutDetailView(log: log)
                }
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

            Text("No Progress Yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Take a progress photo or log a workout to get started.")
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
            if let day = currentDay {
                // Angle picker (only show if current day has photo with multiple angles)
                if let entry = day.photoEntry, entry.photos.count > 1 {
                    Picker("Angle", selection: $displayedAngle) {
                        ForEach(PhotoAngle.allCases.filter { entry.photos[$0] != nil }) { angle in
                            Text(angle.label).tag(angle)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }

                // Main content area
                if let entry = day.photoEntry, let rootURL = appState.rootFolderURL {
                    // Day has a photo — show it
                    ScopedPhotoView(
                        url: entry.photos[displayedAngle] ?? entry.primaryPhoto,
                        scopedURL: rootURL
                    )
                    .id(day.date)
                    .transition(.opacity.animation(.easeInOut(duration: 0.08)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if day.hasWorkout {
                    // Workout-only day — show workout card
                    workoutOnlyCard(day: day)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Workout overlay chip — on days with both photo and workout
                if day.hasPhoto, let log = day.workoutLog {
                    WorkoutOverlayChip(log: log) {
                        selectedWorkoutLog = log
                        showWorkoutDetail = true
                    }
                    .padding(.bottom, 4)
                }

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
                Text(day.date, format: .dateTime.month(.wide).day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)

                // Scrubber
                TimelineScrubber(
                    days: days,
                    selectedIndex: $selectedIndex,
                    scopedURL: appState.rootFolderURL
                )
                .frame(height: 80)
                .padding(.bottom, 8)
            }
        }
    }

    /// Full card shown for workout-only days (no photo)
    @ViewBuilder
    private func workoutOnlyCard(day: TimelineDay) -> some View {
        if let log = day.workoutLog {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text(log.templateName)
                    .font(.title2.bold())

                Text(log.programName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(log.exercises) { exercise in
                        if let best = exercise.sets.max(by: { $0.weight < $1.weight }) {
                            HStack {
                                Text(exercise.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(formatWeight(best.weight)) kg × \(best.reps)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                Button {
                    selectedWorkoutLog = log
                    showWorkoutDetail = true
                } label: {
                    Text("View Full Workout")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)

                Spacer()
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

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
