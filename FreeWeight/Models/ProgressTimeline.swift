import Foundation

@Observable
final class ProgressTimeline {
    var entries: [ProgressEntry] = []

    /// Regex: matches filenames like 2026-03-10_front.jpg
    private static let filenamePattern =
        /^(\d{4}-\d{2}-\d{2})_(\w+)\.jpe?g$/

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Scan the root progress folder, building entries from the
    /// year/month/file hierarchy.
    func scan(rootURL: URL) throws {
        var grouped: [Date: [PhotoAngle: URL]] = [:]

        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            entries = []
            return
        }

        for case let fileURL as URL in enumerator {
            let filename = fileURL.lastPathComponent
            guard let match = filename.wholeMatch(of: Self.filenamePattern) else {
                continue
            }

            let dateString = String(match.1)
            let angleString = String(match.2)

            guard let date = Self.dateFormatter.date(from: dateString),
                  let angle = PhotoAngle(rawValue: angleString) else {
                continue
            }

            grouped[date, default: [:]][angle] = fileURL
        }

        entries = grouped.map { ProgressEntry(date: $0.key, photos: $0.value) }
            .sorted()
    }
}
