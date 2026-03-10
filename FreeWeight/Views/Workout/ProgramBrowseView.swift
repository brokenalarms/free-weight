import SwiftUI

/// First-time / browse screen to pick a program template or create one from scratch.
/// This is the initial selection screen — once a program is active, the user
/// lands on the main workout page instead.
struct ProgramBrowseView: View {
    @Environment(AppState.self) private var appState
    @State private var showCustomEditor = false
    @State private var selectedPreset: ProgramPreset?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Choose a Program")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)

                Text("Pick a template to get started, or build your own.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // Preset programs
                LazyVStack(spacing: 12) {
                    ForEach(ProgramPreset.allPresets) { preset in
                        ProgramPresetCard(preset: preset) {
                            selectedPreset = preset
                        }
                    }
                }
                .padding(.horizontal)

                // Custom
                Button {
                    showCustomEditor = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Build Custom Program")
                                .font(.headline)
                            Text("Define your own rotation and progression")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedPreset) { preset in
            NavigationStack {
                ProgramEditorView(program: preset.toProgram())
            }
        }
        .sheet(isPresented: $showCustomEditor) {
            NavigationStack {
                ProgramEditorView(program: Program(name: ""))
            }
        }
    }
}

// MARK: - Preset Card

struct ProgramPresetCard: View {
    let preset: ProgramPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preset.name)
                        .font(.headline)
                    Spacer()
                    Text("\(preset.daysPerWeek) days/wk")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.accent.opacity(0.15), in: Capsule())
                }

                Text(preset.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    ForEach(preset.templateNames, id: \.self) { name in
                        Text(name)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }

                Text(preset.progressionDescription)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Program Presets

struct ProgramPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let daysPerWeek: Int
    let templateNames: [String]
    let progressionDescription: String
    let templates: [WorkoutTemplate]
    let progression: ProgressionRule

    func toProgram() -> Program {
        Program(
            name: name,
            rotation: templates,
            progression: progression
        )
    }

    static let allPresets: [ProgramPreset] = [ppl, gzclp, upperLower, fullBody]

    static let ppl = ProgramPreset(
        name: "Push / Pull / Legs",
        description: "Classic 6-day split. Each muscle group twice per week.",
        daysPerWeek: 6,
        templateNames: ["Push", "Pull", "Legs"],
        progressionDescription: "+2.5% weekly, deload every 4th week",
        templates: [
            WorkoutTemplate(name: "Push", exercises: [
                Exercise(name: "Bench Press", targetSets: 4, targetReps: 8, weight: 60),
                Exercise(name: "Overhead Press", targetSets: 3, targetReps: 10, weight: 40),
                Exercise(name: "Incline Dumbbell Press", targetSets: 3, targetReps: 12, weight: 22.5),
                Exercise(name: "Lateral Raise", targetSets: 3, targetReps: 15, weight: 10),
                Exercise(name: "Tricep Pushdown", targetSets: 3, targetReps: 12, weight: 25),
            ]),
            WorkoutTemplate(name: "Pull", exercises: [
                Exercise(name: "Deadlift", targetSets: 3, targetReps: 5, weight: 100),
                Exercise(name: "Barbell Row", targetSets: 4, targetReps: 8, weight: 60),
                Exercise(name: "Pull Up", targetSets: 3, targetReps: 8, weight: 0),
                Exercise(name: "Face Pull", targetSets: 3, targetReps: 15, weight: 15),
                Exercise(name: "Barbell Curl", targetSets: 3, targetReps: 12, weight: 25),
            ]),
            WorkoutTemplate(name: "Legs", exercises: [
                Exercise(name: "Squat", targetSets: 4, targetReps: 6, weight: 80),
                Exercise(name: "Romanian Deadlift", targetSets: 3, targetReps: 10, weight: 70),
                Exercise(name: "Leg Press", targetSets: 3, targetReps: 12, weight: 120),
                Exercise(name: "Leg Curl", targetSets: 3, targetReps: 12, weight: 40),
                Exercise(name: "Calf Raise", targetSets: 4, targetReps: 15, weight: 60),
            ]),
        ],
        progression: ProgressionRule(loadWeeks: 3, loadPercent: 2.5, deloadWeeks: 1, deloadPercent: 10)
    )

    static let gzclp = ProgramPreset(
        name: "GZCLP",
        description: "Linear progression 4-day program. Great for intermediates.",
        daysPerWeek: 4,
        templateNames: ["Squat/Bench", "OHP/Dead", "Bench/Squat", "Dead/OHP"],
        progressionDescription: "+5% every 2 weeks, 1 week deload",
        templates: [
            WorkoutTemplate(name: "Squat / Bench", exercises: [
                Exercise(name: "Squat", targetSets: 5, targetReps: 3, weight: 80),
                Exercise(name: "Bench Press", targetSets: 3, targetReps: 10, weight: 50),
                Exercise(name: "Lat Pulldown", targetSets: 3, targetReps: 15, weight: 45),
            ]),
            WorkoutTemplate(name: "OHP / Deadlift", exercises: [
                Exercise(name: "Overhead Press", targetSets: 5, targetReps: 3, weight: 40),
                Exercise(name: "Deadlift", targetSets: 3, targetReps: 10, weight: 80),
                Exercise(name: "Barbell Row", targetSets: 3, targetReps: 15, weight: 45),
            ]),
            WorkoutTemplate(name: "Bench / Squat", exercises: [
                Exercise(name: "Bench Press", targetSets: 5, targetReps: 3, weight: 60),
                Exercise(name: "Squat", targetSets: 3, targetReps: 10, weight: 60),
                Exercise(name: "Lat Pulldown", targetSets: 3, targetReps: 15, weight: 45),
            ]),
            WorkoutTemplate(name: "Deadlift / OHP", exercises: [
                Exercise(name: "Deadlift", targetSets: 5, targetReps: 3, weight: 100),
                Exercise(name: "Overhead Press", targetSets: 3, targetReps: 10, weight: 30),
                Exercise(name: "Barbell Row", targetSets: 3, targetReps: 15, weight: 45),
            ]),
        ],
        progression: ProgressionRule(loadWeeks: 2, loadPercent: 5.0, deloadWeeks: 1, deloadPercent: 10)
    )

    static let upperLower = ProgramPreset(
        name: "Upper / Lower",
        description: "4-day split alternating upper and lower body.",
        daysPerWeek: 4,
        templateNames: ["Upper A", "Lower A", "Upper B", "Lower B"],
        progressionDescription: "+2.5% weekly, deload every 4th week",
        templates: [
            WorkoutTemplate(name: "Upper A", exercises: [
                Exercise(name: "Bench Press", targetSets: 4, targetReps: 6, weight: 60),
                Exercise(name: "Barbell Row", targetSets: 4, targetReps: 6, weight: 60),
                Exercise(name: "Overhead Press", targetSets: 3, targetReps: 10, weight: 35),
                Exercise(name: "Pull Up", targetSets: 3, targetReps: 8, weight: 0),
            ]),
            WorkoutTemplate(name: "Lower A", exercises: [
                Exercise(name: "Squat", targetSets: 4, targetReps: 6, weight: 80),
                Exercise(name: "Romanian Deadlift", targetSets: 3, targetReps: 10, weight: 70),
                Exercise(name: "Leg Press", targetSets: 3, targetReps: 12, weight: 120),
                Exercise(name: "Calf Raise", targetSets: 3, targetReps: 15, weight: 60),
            ]),
            WorkoutTemplate(name: "Upper B", exercises: [
                Exercise(name: "Overhead Press", targetSets: 4, targetReps: 6, weight: 40),
                Exercise(name: "Pull Up", targetSets: 4, targetReps: 6, weight: 0),
                Exercise(name: "Incline Dumbbell Press", targetSets: 3, targetReps: 12, weight: 22.5),
                Exercise(name: "Face Pull", targetSets: 3, targetReps: 15, weight: 15),
            ]),
            WorkoutTemplate(name: "Lower B", exercises: [
                Exercise(name: "Deadlift", targetSets: 4, targetReps: 5, weight: 100),
                Exercise(name: "Front Squat", targetSets: 3, targetReps: 8, weight: 60),
                Exercise(name: "Leg Curl", targetSets: 3, targetReps: 12, weight: 40),
                Exercise(name: "Calf Raise", targetSets: 3, targetReps: 15, weight: 60),
            ]),
        ],
        progression: ProgressionRule(loadWeeks: 3, loadPercent: 2.5, deloadWeeks: 1, deloadPercent: 10)
    )

    static let fullBody = ProgramPreset(
        name: "Full Body 3×/wk",
        description: "Three full body sessions per week. Great for beginners.",
        daysPerWeek: 3,
        templateNames: ["Day A", "Day B", "Day C"],
        progressionDescription: "+5% every 2 weeks, 1 week deload",
        templates: [
            WorkoutTemplate(name: "Day A", exercises: [
                Exercise(name: "Squat", targetSets: 3, targetReps: 5, weight: 60),
                Exercise(name: "Bench Press", targetSets: 3, targetReps: 5, weight: 50),
                Exercise(name: "Barbell Row", targetSets: 3, targetReps: 5, weight: 50),
            ]),
            WorkoutTemplate(name: "Day B", exercises: [
                Exercise(name: "Squat", targetSets: 3, targetReps: 5, weight: 60),
                Exercise(name: "Overhead Press", targetSets: 3, targetReps: 5, weight: 35),
                Exercise(name: "Deadlift", targetSets: 1, targetReps: 5, weight: 80),
            ]),
            WorkoutTemplate(name: "Day C", exercises: [
                Exercise(name: "Squat", targetSets: 3, targetReps: 5, weight: 60),
                Exercise(name: "Bench Press", targetSets: 3, targetReps: 5, weight: 50),
                Exercise(name: "Pull Up", targetSets: 3, targetReps: 8, weight: 0),
            ]),
        ],
        progression: ProgressionRule(loadWeeks: 2, loadPercent: 5.0, deloadWeeks: 1, deloadPercent: 10)
    )
}
