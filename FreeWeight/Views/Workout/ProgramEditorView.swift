import SwiftUI

/// Edit a program: name, rotation of templates, progression rule.
/// Used both for customizing a preset and building from scratch.
struct ProgramEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State var program: Program
    @State private var editingTemplate: WorkoutTemplate?
    @State private var editingTemplateIndex: Int?

    var body: some View {
        Form {
            Section("Program Name") {
                TextField("e.g. GZCLP, PPL, My Program", text: $program.name)
            }

            Section("Rotation") {
                ForEach(Array(program.rotation.enumerated()), id: \.element.id) { idx, template in
                    Button {
                        editingTemplateIndex = idx
                        editingTemplate = template
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name.isEmpty ? "Untitled" : template.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(template.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete { offsets in
                    program.rotation.remove(atOffsets: offsets)
                }
                .onMove { from, to in
                    program.rotation.move(fromOffsets: from, toOffset: to)
                }

                Button {
                    let new = WorkoutTemplate(name: "Day \(program.rotation.count + 1)")
                    program.rotation.append(new)
                    editingTemplateIndex = program.rotation.count - 1
                    editingTemplate = new
                } label: {
                    Label("Add Workout Day", systemImage: "plus")
                }
            }

            Section("Progression") {
                Stepper("Load weeks: \(program.progression.loadWeeks)",
                        value: $program.progression.loadWeeks, in: 1...8)

                HStack {
                    Text("Load increase")
                    Spacer()
                    TextField("", value: $program.progression.loadPercent, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("%")
                }

                Stepper("Deload weeks: \(program.progression.deloadWeeks)",
                        value: $program.progression.deloadWeeks, in: 0...4)

                if program.progression.deloadWeeks > 0 {
                    HStack {
                        Text("Deload reduction")
                        Spacer()
                        TextField("", value: $program.progression.deloadPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                    }
                }

                Text(program.progression.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(program.name.isEmpty ? "New Program" : program.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProgram()
                }
                .disabled(program.name.isEmpty || program.rotation.isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .sheet(item: $editingTemplate) { template in
            NavigationStack {
                TemplateEditorView(template: template) { updated in
                    if let idx = editingTemplateIndex {
                        program.rotation[idx] = updated
                    }
                    editingTemplate = nil
                }
            }
        }
    }

    private func saveProgram() {
        guard let store = appState.workoutStore else { return }
        try? store.saveProgram(program)
        dismiss()
    }
}
