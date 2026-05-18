import Foundation

/// Anonymization boundary, mirroring the Python `AnonymizedEvent`.
/// Only structural metadata is captured. Titles, notes, attendees,
/// locations, URLs, and attachments are never represented here.
struct AnonymizedEvent: Identifiable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let calendar: String
    let isAllDay: Bool

    var durationMinutes: Double {
        end.timeIntervalSince(start) / 60
    }
}
