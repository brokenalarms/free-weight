import Foundation

enum FileError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Cannot access the selected folder. Please re-select it in Settings."
        }
    }
}

struct ProgressFileManager {
    let rootURL: URL

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Scoped access wrapper. All file I/O goes through this.
    func withScopedAccess<T>(_ body: () throws -> T) throws -> T {
        guard rootURL.startAccessingSecurityScopedResource() else {
            throw FileError.accessDenied
        }
        defer { rootURL.stopAccessingSecurityScopedResource() }
        return try body()
    }

    /// Build the path: rootURL/progress/2026/03/2026-03-10_front.jpg
    func destinationURL(for date: Date, angle: PhotoAngle) -> URL {
        let cal = Calendar.current
        let year = String(format: "%04d", cal.component(.year, from: date))
        let month = String(format: "%02d", cal.component(.month, from: date))
        let dateStr = Self.dateFormatter.string(from: date)
        let filename = "\(dateStr)_\(angle.filenameSuffix).jpg"

        return rootURL
            .appending(path: "progress", directoryHint: .isDirectory)
            .appending(path: year, directoryHint: .isDirectory)
            .appending(path: month, directoryHint: .isDirectory)
            .appending(path: filename)
    }

    /// Save JPEG data to the correct location, creating directories as needed.
    func savePhoto(data: Data, date: Date, angle: PhotoAngle) throws -> URL {
        try withScopedAccess {
            let url = destinationURL(for: date, angle: angle)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
            return url
        }
    }

    /// Scan the folder tree and return all entries.
    func loadTimeline() throws -> [ProgressEntry] {
        try withScopedAccess {
            let timeline = ProgressTimeline()
            let progressURL = rootURL.appending(path: "progress", directoryHint: .isDirectory)

            // Create progress directory if it doesn't exist yet
            if !FileManager.default.fileExists(atPath: progressURL.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(
                    at: progressURL,
                    withIntermediateDirectories: true
                )
            }

            try timeline.scan(rootURL: progressURL)
            return timeline.entries
        }
    }
}
