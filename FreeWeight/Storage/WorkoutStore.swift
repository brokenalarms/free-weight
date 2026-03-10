import Foundation

/// Persists workout data as JSON in the app's own Documents directory.
/// Syncs to iCloud via ubiquity container when available, falls back to local.
///
/// Layout (local):
///   Documents/
///     workouts/
///       program.json
///       logs/
///         2026-03-10.json
///
/// Layout (iCloud):
///   iCloud container/Documents/
///     workouts/
///       program.json
///       logs/
///         2026-03-10.json
///
/// Export format (.fwprogram / .fwlog):
///   Standard JSON with schema version for portability.
@Observable
final class WorkoutStore {
    private let fileManager = FileManager.default

    var activeProgram: Program?
    var logs: [Date: WorkoutLog] = [:]
    var iCloudAvailable: Bool = false

    /// Root directory — iCloud container if available, else app Documents
    private var storageRoot: URL {
        if let icloud = iCloudRoot {
            return icloud
        }
        return localRoot
    }

    private var localRoot: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var iCloudRoot: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?
            .appending(path: "Documents", directoryHint: .isDirectory)
    }

    private var workoutsURL: URL {
        storageRoot.appending(path: "workouts", directoryHint: .isDirectory)
    }
    private var programURL: URL {
        workoutsURL.appending(path: "program.json")
    }
    private var logsURL: URL {
        workoutsURL.appending(path: "logs", directoryHint: .isDirectory)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init() {
        iCloudAvailable = iCloudRoot != nil
    }

    // MARK: - Program

    func loadProgram() throws {
        guard fileManager.fileExists(atPath: programURL.path(percentEncoded: false)) else {
            activeProgram = nil
            return
        }
        let data = try Data(contentsOf: programURL)
        activeProgram = try decoder.decode(Program.self, from: data)
    }

    func saveProgram(_ program: Program) throws {
        try fileManager.createDirectory(at: workoutsURL, withIntermediateDirectories: true)
        let data = try encoder.encode(program)
        try data.write(to: programURL, options: .atomic)
        activeProgram = program
    }

    func clearProgram() throws {
        if fileManager.fileExists(atPath: programURL.path(percentEncoded: false)) {
            try fileManager.removeItem(at: programURL)
        }
        activeProgram = nil
    }

    // MARK: - Logs

    func loadAllLogs() throws {
        logs.removeAll()

        let logsPath = logsURL.path(percentEncoded: false)
        guard fileManager.fileExists(atPath: logsPath) else { return }

        let contents = try fileManager.contentsOfDirectory(
            at: logsURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )

        for fileURL in contents where fileURL.pathExtension == "json" {
            if let log = try? decoder.decode(WorkoutLog.self, from: Data(contentsOf: fileURL)) {
                let calendarDate = Calendar.current.startOfDay(for: log.date)
                logs[calendarDate] = log
            }
        }
    }

    func saveLog(_ log: WorkoutLog) throws {
        try fileManager.createDirectory(at: logsURL, withIntermediateDirectories: true)
        let dateStr = Self.dateFormatter.string(from: log.date)
        let fileURL = logsURL.appending(path: "\(dateStr).json")
        let data = try encoder.encode(log)
        try data.write(to: fileURL, options: .atomic)

        let calendarDate = Calendar.current.startOfDay(for: log.date)
        logs[calendarDate] = log
    }

    func log(for date: Date) -> WorkoutLog? {
        logs[Calendar.current.startOfDay(for: date)]
    }

    // MARK: - Performance History

    /// Find the most recent logged performances of a given exercise
    /// across all sessions of a specific template, sorted newest first.
    func recentPerformances(
        exerciseName: String,
        templateName: String,
        limit: Int = 5
    ) -> [WorkoutLog.LoggedExercise] {
        logs.values
            .filter { $0.templateName == templateName }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .compactMap { log in
                log.exercises.first { $0.name == exerciseName }
            }
    }

    /// Calculate the next target for an exercise based on last performance
    /// and the program's progression rule.
    func nextTarget(
        exercise: Exercise,
        templateName: String,
        progression: ProgressionRule
    ) -> ExerciseTarget {
        let history = recentPerformances(
            exerciseName: exercise.name,
            templateName: templateName
        )

        // No history — use template defaults
        guard let lastPerformance = history.first else {
            return ExerciseTarget(
                weight: exercise.weight,
                reps: exercise.targetReps,
                sets: exercise.targetSets,
                isDeload: false
            )
        }

        let completedSets = lastPerformance.sets.filter { $0.completed }
        let hitAllSets = completedSets.count >= exercise.targetSets
        let hitAllReps = hitAllSets && completedSets.allSatisfy { $0.reps >= exercise.targetReps }
        let lastWeight = completedSets.first?.weight ?? exercise.weight
        let lastReps = completedSets.first?.reps ?? exercise.targetReps

        // Scheduled deload check
        if progression.deloadEveryNWeeks > 0 {
            let sessionsForThisTemplate = logs.values
                .filter { $0.templateName == templateName }
                .count
            let rotationCount = sessionsForThisTemplate
            if let program = activeProgram, !program.rotation.isEmpty {
                let weeksCompleted = rotationCount / program.rotation.count
                let cycleLen = progression.deloadEveryNWeeks
                if cycleLen > 0 && weeksCompleted > 0 && weeksCompleted % cycleLen == 0 {
                    // Check if last session was already a deload
                    let deloadWeight = roundToPlate(lastWeight * (1.0 - progression.deloadPercent / 100.0))
                    if lastWeight > deloadWeight + 0.1 {
                        return ExerciseTarget(
                            weight: deloadWeight,
                            reps: exercise.targetReps,
                            sets: exercise.targetSets,
                            isDeload: true
                        )
                    }
                }
            }
        }

        // Success — hit all target sets × reps: increase weight
        if hitAllReps {
            let newWeight = roundToPlate(lastWeight + progression.weightIncrement)
            return ExerciseTarget(
                weight: newWeight,
                reps: exercise.targetReps,
                sets: exercise.targetSets,
                isDeload: false
            )
        }

        // Failure — apply failure strategy
        let consecutiveFailures = countConsecutiveFailures(
            history: history,
            targetReps: exercise.targetReps,
            targetSets: exercise.targetSets
        )

        switch progression.failureStrategy {
        case .retrySameWeight:
            if consecutiveFailures >= progression.maxRetries {
                // Deload
                let deloaded = roundToPlate(lastWeight * (1.0 - progression.deloadPercent / 100.0))
                return ExerciseTarget(
                    weight: deloaded,
                    reps: exercise.targetReps,
                    sets: exercise.targetSets,
                    isDeload: true
                )
            }
            // Retry same
            return ExerciseTarget(
                weight: lastWeight,
                reps: exercise.targetReps,
                sets: exercise.targetSets,
                isDeload: false
            )

        case .dropReps:
            // Find the current rep tier
            let tiers = progression.repTiers.isEmpty ? [5, 3, 1] : progression.repTiers
            let currentTierIndex = tiers.firstIndex(where: { $0 <= lastReps }) ?? 0

            if hitAllSets && lastReps >= (tiers[safe: currentTierIndex] ?? lastReps) {
                // Hit the lower rep target — bump weight, reset to top tier
                let newWeight = roundToPlate(lastWeight + progression.weightIncrement)
                return ExerciseTarget(
                    weight: newWeight,
                    reps: tiers[0],
                    sets: exercise.targetSets,
                    isDeload: false
                )
            }

            // Drop to next tier
            let nextTierIndex = min(currentTierIndex + 1, tiers.count - 1)
            if nextTierIndex > currentTierIndex {
                return ExerciseTarget(
                    weight: lastWeight,
                    reps: tiers[nextTierIndex],
                    sets: exercise.targetSets,
                    isDeload: false
                )
            }

            // At lowest tier and still failing — deload
            let deloaded = roundToPlate(lastWeight * (1.0 - progression.deloadPercent / 100.0))
            return ExerciseTarget(
                weight: deloaded,
                reps: tiers[0],
                sets: exercise.targetSets,
                isDeload: true
            )

        case .dropWeight:
            let deloaded = roundToPlate(lastWeight * (1.0 - progression.deloadPercent / 100.0))
            return ExerciseTarget(
                weight: deloaded,
                reps: exercise.targetReps,
                sets: exercise.targetSets,
                isDeload: false
            )
        }
    }

    // MARK: - Helpers

    /// Count how many consecutive recent sessions failed to hit the target.
    private func countConsecutiveFailures(
        history: [WorkoutLog.LoggedExercise],
        targetReps: Int,
        targetSets: Int
    ) -> Int {
        var count = 0
        for perf in history {
            let completed = perf.sets.filter { $0.completed }
            let hitAll = completed.count >= targetSets
                && completed.allSatisfy { $0.reps >= targetReps }
            if hitAll { break }
            count += 1
        }
        return count
    }

    /// Round to nearest 2.5 kg plate increment
    private func roundToPlate(_ weight: Double) -> Double {
        (weight / 2.5).rounded() * 2.5
    }

    // MARK: - Export

    func exportProgram() throws -> URL {
        guard let program = activeProgram else {
            throw WorkoutStoreError.noProgramToExport
        }
        let export = ProgramExport(schemaVersion: 1, program: program)
        let data = try encoder.encode(export)
        let tempURL = fileManager.temporaryDirectory
            .appending(path: "\(program.name.sanitizedFilename()).fwprogram")
        try data.write(to: tempURL, options: .atomic)
        return tempURL
    }

    func exportLogs() throws -> URL {
        let allLogs = logs.values.sorted { $0.date < $1.date }
        let export = LogsExport(schemaVersion: 1, logs: Array(allLogs))
        let data = try encoder.encode(export)
        let tempURL = fileManager.temporaryDirectory
            .appending(path: "workout-logs.fwlogs")
        try data.write(to: tempURL, options: .atomic)
        return tempURL
    }

    // MARK: - Import

    func importProgram(from url: URL) throws -> Program {
        let data = try Data(contentsOf: url)
        let export = try decoder.decode(ProgramExport.self, from: data)
        return export.program
    }

    func importLogs(from url: URL) throws -> Int {
        let data = try Data(contentsOf: url)
        let export = try decoder.decode(LogsExport.self, from: data)
        var imported = 0
        for log in export.logs {
            try saveLog(log)
            imported += 1
        }
        return imported
    }
}

// MARK: - Export Wrappers (versioned for forward compat)

struct ProgramExport: Codable {
    let schemaVersion: Int
    let program: Program
}

struct LogsExport: Codable {
    let schemaVersion: Int
    let logs: [WorkoutLog]
}

enum WorkoutStoreError: LocalizedError {
    case noProgramToExport

    var errorDescription: String? {
        switch self {
        case .noProgramToExport:
            return "No active program to export."
        }
    }
}

// MARK: - Helpers

extension String {
    func sanitizedFilename() -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        return unicodeScalars
            .filter { allowed.contains($0) }
            .map { Character($0) }
            .map { String($0) }
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "-")
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
