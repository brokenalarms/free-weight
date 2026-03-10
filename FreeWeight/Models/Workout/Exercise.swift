import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var targetSets: Int
    var targetReps: Int
    var weight: Double          // kg
    var restSeconds: Int = 90
    var notes: String = ""
}
