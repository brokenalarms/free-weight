import Foundation

enum PhotoAngle: String, CaseIterable, Identifiable, Codable {
    case front
    case side
    case back

    var id: String { rawValue }

    var label: String {
        switch self {
        case .front: "Front"
        case .side:  "Side"
        case .back:  "Back"
        }
    }

    /// Suffix used in filename: 2026-03-10_front.jpg
    var filenameSuffix: String { rawValue }
}
