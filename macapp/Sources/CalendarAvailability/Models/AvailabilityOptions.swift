import Foundation
import Observation

@Observable
final class AvailabilityOptions {
    var weekStart: Date
    var dayStartHour: Int = 9
    var dayEndHour: Int = 20
    var lunchEnabled: Bool = true
    var lunchStartHour: Int = 12
    var lunchEndHour: Int = 14
    var hideEventTimes: Bool = false
    var includeWeekends: Bool = true
    var selectedCalendarIDs: Set<String> = []   // empty == include all

    /// Which event-availability classes (busy / tentative / free /
    /// unavailable) are drawn on the chart. Default is everything *except*
    /// `.free` — events explicitly marked free are usually noise on a
    /// "when am I blocked?" screenshot, but the user can toggle them on.
    var visibleAvailabilities: Set<EventAvailability> = [.busy, .tentative, .unavailable]

    /// Timezone used for displaying the chart and computing day/week
    /// boundaries. Defaults to the system timezone. Changing this
    /// preserves the ISO week being viewed — the start moment is
    /// recomputed so the same Monday–Sunday window stays visible.
    var timezone: TimeZone {
        didSet { rebaseWeekStart(from: oldValue) }
    }

    init() {
        let tz = TimeZone.current
        self.timezone = tz
        self.weekStart = Self.startOfISOWeek(containing: Date(), in: tz)
    }

    var weekEnd: Date {
        isoCalendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    var fetchWindow: (start: Date, end: Date) {
        let start = isoCalendar.startOfDay(for: weekStart)
        let end = isoCalendar.date(byAdding: .day, value: 7, to: start)!
            .addingTimeInterval(-1)
        return (start, end)
    }

    var weekISOLabel: String {
        let comps = isoCalendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: weekStart
        )
        return String(format: "%d-W%02d",
                      comps.yearForWeekOfYear ?? 0,
                      comps.weekOfYear ?? 0)
    }

    func step(weeks: Int) {
        if let d = isoCalendar.date(byAdding: .weekOfYear, value: weeks, to: weekStart) {
            weekStart = Self.startOfISOWeek(containing: d, in: timezone)
        }
    }

    func resetToCurrentWeek() {
        weekStart = Self.startOfISOWeek(containing: Date(), in: timezone)
    }

    var isoCalendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timezone
        return cal
    }

    // MARK: - Timezone change handling

    /// Re-anchor weekStart so the visible ISO week stays the same when
    /// the user switches timezones (otherwise the moment-stored Date
    /// would silently shift the displayed days by the offset delta).
    private func rebaseWeekStart(from oldTZ: TimeZone) {
        var oldCal = Calendar(identifier: .iso8601)
        oldCal.timeZone = oldTZ
        let comps = oldCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)

        var newCal = Calendar(identifier: .iso8601)
        newCal.timeZone = timezone
        if let rebased = newCal.date(from: comps) {
            weekStart = rebased
        }
    }

    static func startOfISOWeek(containing date: Date, in tz: TimeZone) -> Date {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = tz
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }
}
