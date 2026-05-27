import Foundation
import Observation

@Observable
final class AvailabilityOptions {
    /// `weekStart` is intentionally transient — every launch begins on
    /// the current ISO week regardless of where the user was when they
    /// quit. Everything else round-trips through `PreferencesStore`.
    var weekStart: Date

    var dayStartHour: Int {
        didSet { store.set(dayStartHour, for: PreferencesStore.Keys.dayStartHour) }
    }
    var dayEndHour: Int {
        didSet { store.set(dayEndHour, for: PreferencesStore.Keys.dayEndHour) }
    }
    var lunchEnabled: Bool {
        didSet { store.set(lunchEnabled, for: PreferencesStore.Keys.lunchEnabled) }
    }
    var lunchStartHour: Int {
        didSet { store.set(lunchStartHour, for: PreferencesStore.Keys.lunchStartHour) }
    }
    var lunchEndHour: Int {
        didSet { store.set(lunchEndHour, for: PreferencesStore.Keys.lunchEndHour) }
    }
    var hideEventTimes: Bool {
        didSet { store.set(hideEventTimes, for: PreferencesStore.Keys.hideEventTimes) }
    }
    var includeWeekends: Bool {
        didSet { store.set(includeWeekends, for: PreferencesStore.Keys.includeWeekends) }
    }
    var selectedCalendarIDs: Set<String> {
        didSet {
            store.set(Array(selectedCalendarIDs),
                      for: PreferencesStore.Keys.selectedCalendarIDs)
        }
    }

    /// Which event-availability classes (busy / tentative / free /
    /// unavailable) are drawn on the chart. Default is everything *except*
    /// `.free` — events explicitly marked free are usually noise on a
    /// "when am I blocked?" screenshot, but the user can toggle them on.
    var visibleAvailabilities: Set<EventAvailability> {
        didSet {
            store.set(visibleAvailabilities.map(\.rawValue),
                      for: PreferencesStore.Keys.visibleAvailabilities)
        }
    }

    /// Timezone used for displaying the chart and computing day/week
    /// boundaries. Defaults to the system timezone. Changing this
    /// preserves the ISO week being viewed — the start moment is
    /// recomputed so the same Monday–Sunday window stays visible.
    var timezone: TimeZone {
        didSet {
            rebaseWeekStart(from: oldValue)
            store.set(timezone.identifier,
                      for: PreferencesStore.Keys.timezoneIdentifier)
        }
    }

    private let store: PreferencesStore

    init(store: PreferencesStore = .shared) {
        self.store = store

        self.dayStartHour      = store.int(PreferencesStore.Keys.dayStartHour,      default: 9)
        self.dayEndHour        = store.int(PreferencesStore.Keys.dayEndHour,        default: 20)
        self.lunchEnabled      = store.bool(PreferencesStore.Keys.lunchEnabled,     default: true)
        self.lunchStartHour    = store.int(PreferencesStore.Keys.lunchStartHour,    default: 12)
        self.lunchEndHour      = store.int(PreferencesStore.Keys.lunchEndHour,      default: 14)
        self.hideEventTimes    = store.bool(PreferencesStore.Keys.hideEventTimes,   default: false)
        self.includeWeekends   = store.bool(PreferencesStore.Keys.includeWeekends,  default: true)

        if let savedIDs = store.stringArray(PreferencesStore.Keys.selectedCalendarIDs) {
            self.selectedCalendarIDs = Set(savedIDs)
        } else {
            self.selectedCalendarIDs = []
        }

        if let savedRaws = store.stringArray(PreferencesStore.Keys.visibleAvailabilities) {
            self.visibleAvailabilities = Set(savedRaws.compactMap(EventAvailability.init(rawValue:)))
        } else {
            self.visibleAvailabilities = [.busy, .tentative, .unavailable]
        }

        let tz: TimeZone
        if let id = store.string(PreferencesStore.Keys.timezoneIdentifier),
           let saved = TimeZone(identifier: id) {
            tz = saved
        } else {
            tz = .current
        }
        self.timezone = tz
        self.weekStart = Self.startOfISOWeek(containing: Date(), in: tz)
    }

    /// Restore every persisted property to its literal default. The
    /// per-property `didSet` blocks re-write the cleared keys, so disk
    /// stays in sync.
    func resetToDefaults() {
        store.reset()
        dayStartHour         = 9
        dayEndHour           = 20
        lunchEnabled         = true
        lunchStartHour       = 12
        lunchEndHour         = 14
        hideEventTimes       = false
        includeWeekends      = true
        selectedCalendarIDs  = []
        visibleAvailabilities = [.busy, .tentative, .unavailable]
        timezone             = .current
        weekStart            = Self.startOfISOWeek(containing: Date(), in: timezone)
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
