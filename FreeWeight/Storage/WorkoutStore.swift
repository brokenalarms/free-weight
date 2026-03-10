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

    // MARK: - Export

    /// Export the active program as a portable JSON file.
    /// Returns a temporary file URL suitable for UIActivityViewController / ShareLink.
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

    /// Export all workout logs as a single JSON file.
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

    /// Import a program from a .fwprogram JSON file.
    func importProgram(from url: URL) throws -> Program {
        let data = try Data(contentsOf: url)
        let export = try decoder.decode(ProgramExport.self, from: data)
        return export.program
    }

    /// Import logs from a .fwlogs JSON file, merging with existing.
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

// MARK: - String Helpers

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
