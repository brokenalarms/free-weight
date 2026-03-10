import SwiftUI

/// Quick-log view for recording a workout session at the gym.
///
/// Shows each exercise with target sets/reps/weight.
/// User taps to log actual reps and weight per set.
/// On finish, saves the log and advances the program rotation.
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
        loggedExercises = template.exercises.map { exercise in
            let adjustedWeight = program.adjustedWeight(base: exercise.weight)
            return LoggedExerciseState(
                name: exercise.name,
                sets: (0..<exercise.targetSets).map { _ in
                    SetState(targetReps: exercise.targetReps, weight: adjustedWeight)
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
            Text(exercise.name)
                .font(.headline)

            // Column headers
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
                SetRowView(setNumber: idx + 1, set: $exercise.sets[idx])
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SetRowView: View {
    let setNumber: Int
    @Binding var set: SetState

    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 36)

            Spacer()

            // Weight
            TextField("", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

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
