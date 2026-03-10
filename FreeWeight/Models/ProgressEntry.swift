import Foundation

struct ProgressEntry: Identifiable, Comparable {
    let date: Date
    /// Keyed by angle → file URL within the user's folder
    var photos: [PhotoAngle: URL]

    var id: Date { date }

    /// The primary display photo (always front if it exists)
    var primaryPhoto: URL? { photos[.front] ?? photos.values.first }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date < rhs.date
    }
}
