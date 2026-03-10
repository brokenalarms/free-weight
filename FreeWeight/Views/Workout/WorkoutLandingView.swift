import SwiftUI

/// The main workout landing page.
///
/// If a program is active: shows "GZCLP — Upper Power" with a big Start button.
/// If no program: shows ProgramBrowseView to pick/create one.
struct WorkoutLandingView: View {
    @Environment(AppState.self) private var appState
    @State private var showActiveSession = false
    @State private var showBrowse = false
    @State private var showEditProgram = false

    private var store: WorkoutStore? { appState.workoutStore }
    private var program: Program? { store?.activeProgram }

    var body: some View {
        NavigationStack {
            Group {
                if let program, let nextTemplate = program.nextTemplate {
                    activeProgramView(program: program, next: nextTemplate)
                } else {
                    ProgramBrowseView()
                }
            }
            .navigationDestination(isPresented: $showActiveSession) {
                if let program, let next = program.nextTemplate {
                    QuickLogView(
                        template: next,
                        program: program
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func activeProgramView(program: Program, next: WorkoutTemplate) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Program name
            Text(program.name)
                .font(.title3)
                .foregroundStyle(.secondary)

            // Next workout name
            Text(next.name)
                .font(.largeTitle.bold())
                .padding(.top, 4)

            // Progression status
            progressionChip(program: program)
                .padding(.top, 12)

            // Exercise preview
            exercisePreview(template: next, program: program)
                .padding(.top, 24)

            Spacer()

            // Start button
            Button {
                showActiveSession = true
            } label: {
                Text("Start Workout")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            // Session counter
            Text("Session \(program.completedSessions + 1) · \(next.name)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 24)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditProgram = true
                    } label: {
                        Label("Edit Program", systemImage: "pencil")
                    }
                    Button {
                        showBrowse = true
                    } label: {
                        Label("Switch Program", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button(role: .destructive) {
                        try? store?.clearProgram()
                    } label: {
                        Label("Remove Program", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showBrowse) {
            NavigationStack {
                ProgramBrowseView()
            }
        }
        .sheet(isPresented: $showEditProgram) {
            NavigationStack {
                ProgramEditorView(program: program)
            }
        }
    }

    @ViewBuilder
    private func progressionChip(program: Program) -> some View {
        let weekInCycle = program.currentWeekInCycle
        let isDeload = weekInCycle >= program.progression.loadWeeks

        HStack(spacing: 6) {
            Circle()
                .fill(isDeload ? .orange : .green)
                .frame(width: 8, height: 8)
            Text(isDeload ? "Deload Week" : "Week \(weekInCycle + 1) of \(program.progression.loadWeeks)")
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.quaternary, in: Capsule())
    }

    @ViewBuilder
    private func exercisePreview(template: WorkoutTemplate, program: Program) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(template.exercises) { exercise in
                HStack {
                    Text(exercise.name)
                        .font(.subheadline)
                    Spacer()
                    let adjusted = program.adjustedWeight(base: exercise.weight)
                    Text("\(exercise.targetSets)×\(exercise.targetReps) @ \(formatWeight(adjusted)) kg")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
