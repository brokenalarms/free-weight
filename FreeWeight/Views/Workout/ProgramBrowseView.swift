import SwiftUI

/// First-time / browse screen to pick a program template or create one from scratch.
/// This is the initial selection screen — once a program is active, the user
/// lands on the main workout page instead.
struct ProgramBrowseView: View {
    @Environment(AppState.self) private var appState
    @State private var showCustomEditor = false
    @State private var selectedPreset: ProgramPreset?
    @State private var showImportPicker = false
    @State private var importedProgram: Program?

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

                // Import
                Button {
                    showImportPicker = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Import Program")
                                .font(.headline)
                            Text("Load a shared .fwprogram file")
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
        .sheet(isPresented: $showImportPicker) {
            ProgramImportPicker { url in
                if let program = try? appState.workoutStore.importProgram(from: url) {
                    importedProgram = program
                }
            }
        }
        .sheet(item: $importedProgram) { program in
            NavigationStack {
                ProgramEditorView(program: program)
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

    static let allPresets: [ProgramPreset] = [ppl, gzclp, upperLower, fullBody, mapsAnabolic, strengthMobility, calisthenicsHybrid]

    static let ppl = ProgramPreset(
        name: "Push / Pull / Legs",
        description: "Classic 6-day split. Each muscle group twice per week.",
        daysPerWeek: 6,
        templateNames: ["Push", "Pull", "Legs"],
        progressionDescription: "+2.5 kg on success, retry on fail, deload every 4 weeks",
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
        progression: ProgressionRule(
            weightIncrement: 2.5,
            failureStrategy: .retrySameWeight,
            maxRetries: 2,
            deloadPercent: 10,
            deloadEveryNWeeks: 4
        )
    )

    static let gzclp = ProgramPreset(
        name: "GZCLP",
        description: "Linear progression 4-day program. Great for intermediates.",
        daysPerWeek: 4,
        templateNames: ["Squat/Bench", "OHP/Dead", "Bench/Squat", "Dead/OHP"],
        progressionDescription: "+2.5 kg on success, drop reps on fail (5→3→1)",
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
        progression: ProgressionRule(
            weightIncrement: 2.5,
            failureStrategy: .dropReps,
            maxRetries: 2,
            deloadPercent: 10,
            repTiers: [5, 3, 1],
            deloadEveryNWeeks: 0
        )
    )

    static let upperLower = ProgramPreset(
        name: "Upper / Lower",
        description: "4-day split alternating upper and lower body.",
        daysPerWeek: 4,
        templateNames: ["Upper A", "Lower A", "Upper B", "Lower B"],
        progressionDescription: "+2.5 kg on success, retry on fail, deload every 4 weeks",
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
        progression: ProgressionRule(
            weightIncrement: 2.5,
            failureStrategy: .retrySameWeight,
            maxRetries: 2,
            deloadPercent: 10,
            deloadEveryNWeeks: 4
        )
    )

    static let fullBody = ProgramPreset(
        name: "Full Body 3×/wk",
        description: "Three full body sessions per week. Great for beginners.",
        daysPerWeek: 3,
        templateNames: ["Day A", "Day B", "Day C"],
        progressionDescription: "+2.5 kg on success, retry on fail, deload every 4 weeks",
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
        progression: ProgressionRule(
            weightIncrement: 2.5,
            failureStrategy: .retrySameWeight,
            maxRetries: 3,
            deloadPercent: 10,
            deloadEveryNWeeks: 0
        )
    )

    static let mapsAnabolic = ProgramPreset(
        name: "MAPS Periodized Full Body",
        description: "3-day full body with compound focus. Periodized progression with scheduled deloads.",
        daysPerWeek: 3,
        templateNames: ["Full Body A", "Full Body B", "Full Body C"],
        progressionDescription: "+2.5 kg on success, retry on fail, deload every 4 weeks",
        templates: [
            WorkoutTemplate(name: "Full Body A", exercises: [
                Exercise(name: "Barbell Squat", targetSets: 4, targetReps: 8, weight: 70),
                Exercise(name: "Dumbbell Bench Press", targetSets: 3, targetReps: 10, weight: 25),
                Exercise(name: "Barbell Row", targetSets: 3, targetReps: 10, weight: 50),
                Exercise(name: "Dumbbell Shoulder Press", targetSets: 3, targetReps: 10, weight: 17.5),
                Exercise(name: "Bicep Curl", targetSets: 2, targetReps: 12, weight: 12.5),
                Exercise(name: "Tricep Overhead Extension", targetSets: 2, targetReps: 12, weight: 15),
            ]),
            WorkoutTemplate(name: "Full Body B", exercises: [
                Exercise(name: "Deadlift", targetSets: 4, targetReps: 6, weight: 90),
                Exercise(name: "Incline Dumbbell Press", targetSets: 3, targetReps: 10, weight: 22.5),
                Exercise(name: "Pull Up", category: .calisthenics, targetSets: 3, targetReps: 8, weight: 0),
                Exercise(name: "Lateral Raise", targetSets: 3, targetReps: 15, weight: 8),
                Exercise(name: "Leg Curl", targetSets: 3, targetReps: 12, weight: 35),
                Exercise(name: "Calf Raise", targetSets: 3, targetReps: 15, weight: 50),
            ]),
            WorkoutTemplate(name: "Full Body C", exercises: [
                Exercise(name: "Front Squat", targetSets: 3, targetReps: 8, weight: 50),
                Exercise(name: "Bench Press", targetSets: 4, targetReps: 8, weight: 60),
                Exercise(name: "Cable Row", targetSets: 3, targetReps: 12, weight: 45),
                Exercise(name: "Romanian Deadlift", targetSets: 3, targetReps: 10, weight: 60),
                Exercise(name: "Face Pull", targetSets: 3, targetReps: 15, weight: 12.5),
                Exercise(name: "Plank", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
            ]),
        ],
        progression: ProgressionRule(
            weightIncrement: 2.5,
            failureStrategy: .retrySameWeight,
            maxRetries: 2,
            deloadPercent: 10,
            deloadEveryNWeeks: 4
        )
    )

    static let strengthMobility = ProgramPreset(
        name: "Strength + Mobility",
        description: "Interleaves gym days with mobility/flexibility sessions you can do anywhere.",
        daysPerWeek: 6,
        templateNames: ["Push", "Mobility", "Pull", "Flexibility", "Legs", "Mobility"],
        progressionDescription: "+2.5 kg on success, retry on fail, deload every 4 weeks",
        templates: [
            WorkoutTemplate(name: "Push", exercises: [
                Exercise(name: "Bench Press", targetSets: 4, targetReps: 8, weight: 60),
                Exercise(name: "Overhead Press", targetSets: 3, targetReps: 10, weight: 40),
                Exercise(name: "Dips", category: .calisthenics, targetSets: 3, targetReps: 12, weight: 0),
                Exercise(name: "Lateral Raise", targetSets: 3, targetReps: 15, weight: 10),
            ]),
            WorkoutTemplate(name: "Mobility A", exercises: [
                Exercise(name: "Shoulder Dislocates", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Hip 90/90 Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Cat-Cow", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "World's Greatest Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Dead Hang", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
            ]),
            WorkoutTemplate(name: "Pull", exercises: [
                Exercise(name: "Deadlift", targetSets: 3, targetReps: 5, weight: 100),
                Exercise(name: "Barbell Row", targetSets: 4, targetReps: 8, weight: 60),
                Exercise(name: "Pull Up", category: .calisthenics, targetSets: 3, targetReps: 8, weight: 0),
                Exercise(name: "Face Pull", targetSets: 3, targetReps: 15, weight: 15),
            ]),
            WorkoutTemplate(name: "Flexibility", exercises: [
                Exercise(name: "Hamstring Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Pigeon Pose", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Couch Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Thoracic Extension", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Pancake Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
            ]),
            WorkoutTemplate(name: "Legs", exercises: [
                Exercise(name: "Squat", targetSets: 4, targetReps: 6, weight: 80),
                Exercise(name: "Romanian Deadlift", targetSets: 3, targetReps: 10, weight: 70),
                Exercise(name: "Bulgarian Split Squat", category: .calisthenics, targetSets: 3, targetReps: 10, weight: 0),
                Exercise(name: "Calf Raise", targetSets: 4, targetReps: 15, weight: 60),
            ]),
            WorkoutTemplate(name: "Mobility B", exercises: [
                Exercise(name: "Foam Roll Quads", category: .mobility, targetSets: 2, targetReps: 1, weight: 0, durationSeconds: 60),
                Exercise(name: "Foam Roll Back", category: .mobility, targetSets: 2, targetReps: 1, weight: 0, durationSeconds: 60),
                Exercise(name: "Ankle Circles", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Wall Slides", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Deep Squat Hold", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
            ]),
        ],
        progression: ProgressionRule(
            weightIncrement: 2.5,
            failureStrategy: .retrySameWeight,
            maxRetries: 2,
            deloadPercent: 10,
            deloadEveryNWeeks: 4
        )
    )

    static let calisthenicsHybrid = ProgramPreset(
        name: "Calisthenics Hybrid",
        description: "Bodyweight skills with barbell compounds. Mobility built into every session.",
        daysPerWeek: 4,
        templateNames: ["Upper", "Mobility", "Lower", "Mobility"],
        progressionDescription: "+2.5 kg compounds, bodyweight reps progress, deload every 4 weeks",
        templates: [
            WorkoutTemplate(name: "Upper Strength + Skills", exercises: [
                Exercise(name: "Bench Press", targetSets: 4, targetReps: 6, weight: 60),
                Exercise(name: "Pull Up", category: .calisthenics, targetSets: 4, targetReps: 8, weight: 0),
                Exercise(name: "Push Up", category: .calisthenics, targetSets: 3, targetReps: 20, weight: 0),
                Exercise(name: "Inverted Row", category: .calisthenics, targetSets: 3, targetReps: 12, weight: 0),
                Exercise(name: "L-Sit Hold", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 20),
            ]),
            WorkoutTemplate(name: "Upper Mobility", exercises: [
                Exercise(name: "Shoulder Dislocates", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Chest Opener Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Wrist Circles", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Dead Hang", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
                Exercise(name: "Thoracic Rotation", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
            ]),
            WorkoutTemplate(name: "Lower Strength + Skills", exercises: [
                Exercise(name: "Squat", targetSets: 4, targetReps: 6, weight: 80),
                Exercise(name: "Deadlift", targetSets: 3, targetReps: 5, weight: 100),
                Exercise(name: "Pistol Squat", category: .calisthenics, targetSets: 3, targetReps: 5, weight: 0),
                Exercise(name: "Glute Bridge", category: .calisthenics, targetSets: 3, targetReps: 15, weight: 0),
                Exercise(name: "Deep Squat Hold", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
            ]),
            WorkoutTemplate(name: "Lower Mobility", exercises: [
                Exercise(name: "Hip 90/90 Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Pigeon Pose", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Couch Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Hamstring Stretch", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 45),
                Exercise(name: "Ankle Mobility", category: .mobility, targetSets: 3, targetReps: 1, weight: 0, durationSeconds: 30),
            ]),
        ],
        progression: ProgressionRule(
            weightIncrement: 2.5,
            failureStrategy: .retrySameWeight,
            maxRetries: 2,
            deloadPercent: 10,
            deloadEveryNWeeks: 4
        )
    )
}
