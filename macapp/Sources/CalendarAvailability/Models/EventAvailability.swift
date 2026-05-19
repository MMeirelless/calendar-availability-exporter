import Foundation

/// Mirrors `EKEventAvailability` but kept as our own enum so the rest of
/// the app never touches EventKit types directly (same anonymization
/// posture as the rest of the model layer).
enum EventAvailability: String, CaseIterable, Identifiable, Hashable, Codable {
    case busy
    case tentative
    case free
    case unavailable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .busy:        return "Busy"
        case .tentative:   return "Tentative"
        case .free:        return "Free"
        case .unavailable: return "Unavailable"
        }
    }

    /// Stable ordering for UI lists and the legend.
    static let ordered: [EventAvailability] = [.busy, .tentative, .free, .unavailable]
}
