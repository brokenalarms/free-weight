import Foundation

/// Persists workout data as JSON files in the user's chosen folder.
///
/// Layout:
///   rootURL/
///     workouts/
///       program.json          ← The active program definition
///       logs/
///         2026-03-10.json     ← One log file per day (matches photo dates)
@Observable
final class WorkoutStore {
    private let rootURL: URL
    private let fileManager = FileManager.default

    var activeProgram: Program?
    var logs: [Date: WorkoutLog] = [:]          // Date → log lookup for timeline overlay

    private var workoutsURL: URL {
        rootURL.appending(path: "workouts", directoryHint: .isDirectory)
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

    init(rootURL: URL) {
        self.rootURL = rootURL
    }

    // MARK: - Scoped Access

    private func withScopedAccess<T>(_ body: () throws -> T) throws -> T {
        guard rootURL.startAccessingSecurityScopedResource() else {
            throw FileError.accessDenied
        }
        defer { rootURL.stopAccessingSecurityScopedResource() }
        return try body()
    }

    // MARK: - Program

    func loadProgram() throws {
        try withScopedAccess {
            guard fileManager.fileExists(atPath: programURL.path(percentEncoded: false)) else {
                activeProgram = nil
                return
            }
            let data = try Data(contentsOf: programURL)
            activeProgram = try decoder.decode(Program.self, from: data)
        }
    }

    func saveProgram(_ program: Program) throws {
        try withScopedAccess {
            try fileManager.createDirectory(at: workoutsURL, withIntermediateDirectories: true)
            let data = try encoder.encode(program)
            try data.write(to: programURL, options: .atomic)
            activeProgram = program
        }
    }

    func clearProgram() throws {
        try withScopedAccess {
            if fileManager.fileExists(atPath: programURL.path(percentEncoded: false)) {
                try fileManager.removeItem(at: programURL)
            }
            activeProgram = nil
        }
    }

    // MARK: - Logs

    func loadAllLogs() throws {
        try withScopedAccess {
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
    }

    func saveLog(_ log: WorkoutLog) throws {
        try withScopedAccess {
            try fileManager.createDirectory(at: logsURL, withIntermediateDirectories: true)
            let dateStr = Self.dateFormatter.string(from: log.date)
            let fileURL = logsURL.appending(path: "\(dateStr).json")
            let data = try encoder.encode(log)
            try data.write(to: fileURL, options: .atomic)

            let calendarDate = Calendar.current.startOfDay(for: log.date)
            logs[calendarDate] = log
        }
    }

    func log(for date: Date) -> WorkoutLog? {
        logs[Calendar.current.startOfDay(for: date)]
    }
}
