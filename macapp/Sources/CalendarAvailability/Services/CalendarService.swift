import EventKit
import Foundation
import Observation

/// Wraps EventKit access, mirroring the anonymization boundary of
/// the Python `eventkit_client.py`: only start, end, calendar title,
/// and isAllDay are ever read from EKEvent.
@Observable
@MainActor
final class CalendarService {
    enum Status: Equatable {
        case unknown
        case requesting
        case granted
        case denied
        case error(String)
    }

    private let store = EKEventStore()

    var status: Status = .unknown
    var calendars: [EKCalendar] = []

    func requestAccess() async {
        let current = EKEventStore.authorizationStatus(for: .event)
        if current == .fullAccess {
            await loadCalendars()
            status = .granted
            return
        }
        if current == .denied || current == .restricted {
            status = .denied
            return
        }

        status = .requesting
        do {
            let granted = try await store.requestFullAccessToEvents()
            if granted {
                await loadCalendars()
                status = .granted
            } else {
                status = .denied
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    private func loadCalendars() async {
        calendars = store.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Fetches events in [start, end]. Returns AnonymizedEvent — never EKEvent
    /// instances — so the rest of the app cannot accidentally read titles or
    /// other PII. Recurring events are expanded by EventKit's predicate.
    func fetchEvents(
        start: Date,
        end: Date,
        calendarIDs: Set<String>
    ) -> [AnonymizedEvent] {
        guard status == .granted else { return [] }

        let pool: [EKCalendar]
        if calendarIDs.isEmpty {
            pool = calendars
        } else {
            pool = calendars.filter { calendarIDs.contains($0.calendarIdentifier) }
        }
        guard !pool.isEmpty else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: pool)
        return store.events(matching: predicate).map { ev in
            AnonymizedEvent(
                id: UUID(),
                start: ev.startDate,
                end: ev.endDate,
                calendar: ev.calendar.title,
                isAllDay: ev.isAllDay
            )
        }
    }

    /// Returns a stable color index per calendar, based on its position in
    /// the sorted calendar list. Used so colors don't shuffle as the week
    /// changes (only the calendars actually present in the current week
    /// would otherwise affect the order).
    func paletteIndex(for calendarTitle: String) -> Int {
        if let i = calendars.firstIndex(where: { $0.title == calendarTitle }) {
            return i
        }
        return abs(calendarTitle.hashValue)
    }
}
