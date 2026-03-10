import Foundation

struct WorkoutTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String                    // "Upper Power", "Pull Day", etc.
    var exercises: [Exercise] = []
}
