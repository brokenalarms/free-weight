import SwiftUI

/// Quick-log view for recording a workout session at the gym (or anywhere).
///
/// Pre-populates each exercise with the next target weight/reps based on
/// last performance and the program's progression rule.
///
/// UX varies by exercise category:
/// - Strength: weight + reps per set, editable
/// - Calisthenics: reps per set, no weight field
/// - Mobility: just tick done per set (duration shown as label)
struct QuickLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate
    let program: Program

    @State private var loggedExercises: [LoggedExerciseState] = []
    @State private var startTime = Date()
    @State private var showFinishConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(template.name)
                            .font(.title2.bold())
                        Text(program.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ElapsedTimeView(start: startTime)
                }
                .padding(.horizontal)

                // Exercise cards
                ForEach($loggedExercises) { $exercise in
                    ExerciseLogCard(exercise: $exercise)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Log Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Finish") {
                    showFinishConfirm = true
                }
                .bold()
            }
        }
        .alert("Finish Workout?", isPresented: $showFinishConfirm) {
            Button("Finish", role: .destructive) { finishWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will save your workout and advance to the next session in the rotation.")
        }
        .onAppear { setupExercises() }
    }

    private func setupExercises() {
        let store = appState.workoutStore
        loggedExercises = template.exercises.map { exercise in
            let target = store.nextTarget(
                exercise: exercise,
                templateName: template.name,
                progression: program.progression
            )
            return LoggedExerciseState(
                name: exercise.name,
                category: exercise.category,
                durationSeconds: exercise.durationSeconds,
                isDeload: target.isDeload,
                sets: (0..<target.sets).map { _ in
                    SetState(targetReps: target.reps, weight: target.weight)
                }
            )
        }
    }

    private func finishWorkout() {
        let duration = Int(Date().timeIntervalSince(startTime))
        let log = WorkoutLog(
            date: Calendar.current.startOfDay(for: .now),
            programName: program.name,
            templateName: template.name,
            exercises: loggedExercises.map { ex in
                WorkoutLog.LoggedExercise(
                    name: ex.name,
                    sets: ex.sets.filter { $0.completed }.map { set in
                        WorkoutLog.LoggedSet(
                            reps: set.actualReps ?? set.targetReps,
                            weight: set.weight,
                            completed: true
                        )
                    }
                )
            },
            durationSeconds: duration
        )

        let store = appState.workoutStore
        try? store.saveLog(log)
        if var prog = store.activeProgram {
            prog.advanceRotation()
            try? store.saveProgram(prog)
        }

        dismiss()
    }
}

// MARK: - State Models (not persisted, just for the logging UI)

struct LoggedExerciseState: Identifiable {
    let id = UUID()
    var name: String
    var category: ExerciseCategory = .strength
    var durationSeconds: Int = 0
    var isDeload: Bool = false
    var sets: [SetState]
}

struct SetState: Identifiable {
    let id = UUID()
    var targetReps: Int
    var weight: Double
    var actualReps: Int?
    var completed: Bool = false
}

// MARK: - Exercise Log Card

struct ExerciseLogCard: View {
    @Binding var exercise: LoggedExerciseState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with category icon
            HStack {
                Image(systemName: exercise.category.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(exercise.name)
                    .font(.headline)
                if exercise.isDeload {
                    Text("DELOAD")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }

            switch exercise.category {
            case .strength:
                strengthLayout
            case .calisthenics:
                calisthenicsLayout
            case .mobility:
                mobilityLayout
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Strength: weight + reps per set

    @ViewBuilder
    private var strengthLayout: some View {
        HStack {
            Text("Set")
                .frame(width: 36)
            Spacer()
            Text("kg")
                .frame(width: 60)
            Text("Reps")
                .frame(width: 50)
            Image(systemName: "checkmark")
                .frame(width: 36)
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { idx, _ in
            SetRowView(setNumber: idx + 1, set: $exercise.sets[idx], showWeight: true)
        }
    }

    // MARK: - Calisthenics: reps only

    @ViewBuilder
    private var calisthenicsLayout: some View {
        HStack {
            Text("Set")
                .frame(width: 36)
            Spacer()
            Text("Reps")
                .frame(width: 50)
            Image(systemName: "checkmark")
                .frame(width: 36)
        }
        .font(.caption)
        .foregroundStyle(.secondary)

        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { idx, _ in
            SetRowView(setNumber: idx + 1, set: $exercise.sets[idx], showWeight: false)
        }
    }

    // MARK: - Mobility: just tap to tick done

    @ViewBuilder
    private var mobilityLayout: some View {
        if exercise.durationSeconds > 0 {
            Text("\(exercise.durationSeconds)s hold × \(exercise.sets.count) sets")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }

        HStack(spacing: 12) {
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { idx, _ in
                Button {
                    exercise.sets[idx].completed.toggle()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: exercise.sets[idx].completed
                              ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(exercise.sets[idx].completed ? .green : .secondary)
                        Text("Set \(idx + 1)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

struct SetRowView: View {
    let setNumber: Int
    @Binding var set: SetState
    var showWeight: Bool = true

    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 36)

            Spacer()

            if showWeight {
                TextField("", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .padding(.vertical, 6)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }

            // Reps
            TextField("", value: Binding(
                get: { set.actualReps ?? set.targetReps },
                set: { set.actualReps = $0 }
            ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 50)
                .padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

            // Complete toggle
            Button {
                set.completed.toggle()
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.completed ? .green : .secondary)
            }
            .frame(width: 36)
        }
        .font(.subheadline.monospacedDigit())
    }
}

// MARK: - Elapsed Timer

struct ElapsedTimeView: View {
    let start: Date
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let elapsed = Int(now.timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        Text(String(format: "%d:%02d", minutes, seconds))
            .font(.title3.monospacedDigit())
            .foregroundStyle(.secondary)
            .onReceive(timer) { now = $0 }
    }
}
