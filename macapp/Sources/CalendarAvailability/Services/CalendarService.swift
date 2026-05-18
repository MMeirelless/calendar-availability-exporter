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

    /// EKEventStore is documented thread-safe; opt it out of the MainActor
    /// isolation so we can `await store.requestFullAccessToEvents()` without
    /// Swift 6 flagging a data race on `self.store`.
    nonisolated(unsafe) private let store = EKEventStore()

    var status: Status = .unknown
    var calendars: [EKCalendar] = []

    func requestAccess() async {
        let current = EKEventStore.authorizationStatus(for: .event)
        if current == .fullAccess {
            loadCalendars()
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
                loadCalendars()
                status = .granted
            } else {
                status = .denied
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    private func loadCalendars() {
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

}
