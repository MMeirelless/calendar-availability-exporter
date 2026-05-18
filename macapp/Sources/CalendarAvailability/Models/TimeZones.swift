import Foundation

/// Curated and full-set timezone lists, plus formatting helpers used by the
/// Sidebar picker and the chart subtitle.
enum TimeZones {

    /// A short list of commonly used business timezones, shown at the top
    /// of the picker for quick access.
    static let common: [TimeZone] = [
        "UTC",
        "America/Los_Angeles",
        "America/Denver",
        "America/Chicago",
        "America/New_York",
        "America/Sao_Paulo",
        "Europe/London",
        "Europe/Berlin",
        "Europe/Athens",
        "Asia/Dubai",
        "Asia/Kolkata",
        "Asia/Singapore",
        "Asia/Tokyo",
        "Australia/Sydney",
    ].compactMap(TimeZone.init(identifier:))

    /// All known IANA timezone identifiers, sorted alphabetically.
    static var all: [TimeZone] {
        TimeZone.knownTimeZoneIdentifiers
            .sorted()
            .compactMap(TimeZone.init(identifier:))
    }

    /// "America/Sao_Paulo (UTC−3)" — used as picker labels.
    static func displayName(_ tz: TimeZone) -> String {
        "\(tz.identifier) (\(gmtOffsetLabel(tz)))"
    }

    /// "UTC+0", "UTC−3", "UTC+5:30" — used in the chart subtitle and picker.
    static func gmtOffsetLabel(_ tz: TimeZone) -> String {
        let secs = tz.secondsFromGMT()
        let totalMinutes = abs(secs) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let sign = secs >= 0 ? "+" : "−"
        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }
        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }
}
