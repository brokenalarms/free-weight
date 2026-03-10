import SwiftUI

/// Edit a single workout template: name + list of exercises.
struct TemplateEditorView: View {
    @State var template: WorkoutTemplate
    @Environment(\.dismiss) private var dismiss
    let onSave: (WorkoutTemplate) -> Void

    var body: some View {
        Form {
            Section("Workout Name") {
                TextField("e.g. Push, Upper Power, Day A", text: $template.name)
            }

            Section("Exercises") {
                ForEach($template.exercises) { $exercise in
                    ExerciseRowEditor(exercise: $exercise)
                }
                .onDelete { offsets in
                    template.exercises.remove(atOffsets: offsets)
                }
                .onMove { from, to in
                    template.exercises.move(fromOffsets: from, toOffset: to)
                }

                Button {
                    template.exercises.append(
                        Exercise(name: "", targetSets: 3, targetReps: 10, weight: 0)
                    )
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .navigationTitle(template.name.isEmpty ? "New Workout" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onSave(template)
                    dismiss()
                }
                .disabled(template.name.isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

/// Inline editor for a single exercise within a template.
struct ExerciseRowEditor: View {
    @Binding var exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: exercise.category.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Exercise name", text: $exercise.name)
                    .font(.headline)
            }

            Picker("Category", selection: $exercise.category) {
                ForEach(ExerciseCategory.allCases) { cat in
                    Label(cat.label, systemImage: cat.icon).tag(cat)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("", value: $exercise.targetSets, format: .number)
                        .keyboardType(.numberPad)
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }

                switch exercise.category {
                case .strength:
                    HStack(spacing: 4) {
                        Text("Reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("", value: $exercise.targetReps, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 40)
                            .multilineTextAlignment(.center)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    }

                    HStack(spacing: 4) {
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("", value: $exercise.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    }

                case .calisthenics:
                    HStack(spacing: 4) {
                        Text("Reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("", value: $exercise.targetReps, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 40)
                            .multilineTextAlignment(.center)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    }

                case .mobility:
                    HStack(spacing: 4) {
                        Text("Duration (s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("", value: $exercise.durationSeconds, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
