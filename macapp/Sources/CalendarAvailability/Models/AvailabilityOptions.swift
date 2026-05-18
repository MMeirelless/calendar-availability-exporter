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
    var selectedCalendarIDs: Set<String> = []   // empty == include all

    init() {
        self.weekStart = Self.startOfISOWeek(containing: Date())
    }

    var weekEnd: Date {
        Self.isoCalendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    var fetchWindow: (start: Date, end: Date) {
        let start = Self.isoCalendar.startOfDay(for: weekStart)
        let end = Self.isoCalendar.date(byAdding: .day, value: 7, to: start)!
            .addingTimeInterval(-1)
        return (start, end)
    }

    var weekISOLabel: String {
        let comps = Self.isoCalendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: weekStart
        )
        return String(format: "%d-W%02d",
                      comps.yearForWeekOfYear ?? 0,
                      comps.weekOfYear ?? 0)
    }

    func step(weeks: Int) {
        if let d = Self.isoCalendar.date(byAdding: .weekOfYear, value: weeks, to: weekStart) {
            weekStart = Self.startOfISOWeek(containing: d)
        }
    }

    func resetToCurrentWeek() {
        weekStart = Self.startOfISOWeek(containing: Date())
    }

    static func startOfISOWeek(containing date: Date) -> Date {
        let comps = isoCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return isoCalendar.date(from: comps) ?? date
    }

    private static var isoCalendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        return cal
    }()
}
