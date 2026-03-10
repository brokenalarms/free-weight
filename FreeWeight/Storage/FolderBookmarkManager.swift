import Foundation

enum FolderBookmarkManager {
    private static let bookmarkKey = "rootFolderBookmark"

    /// Save a security-scoped bookmark from a URL returned by the document picker.
    static func saveBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
    }

    /// Resolve the stored bookmark back into a security-scoped URL.
    /// Returns nil if no bookmark is stored or resolution fails.
    static func resolveBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        if isStale {
            try? saveBookmark(for: url)
        }
        return url
    }

    static func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }
}
