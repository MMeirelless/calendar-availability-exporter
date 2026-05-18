"""Thin wrapper around the macOS EventKit framework.

Handles:
    * Permission requests, supporting both pre- and post-macOS 14 APIs.
    * Fetching events in a window, reduced to `AnonymizedEvent` objects.

EventKit handles recurring event expansion automatically when queried with
`predicateForEventsWithStartDate:endDate:calendars:`, so callers do not need
to expand recurrences themselves.
"""

from __future__ import annotations

import sys
import threading
from datetime import datetime

from EventKit import EKEntityTypeEvent, EKEventStore
from Foundation import NSDate

from .models import AnonymizedEvent


def request_calendar_access(store: EKEventStore, timeout: float = 30.0) -> bool:
    """Request Calendar access synchronously.

    On macOS 14+, uses `requestFullAccessToEventsWithCompletion:`.
    On older versions, falls back to `requestAccessToEntityType:completion:`.

    Args:
        store:   An `EKEventStore` instance.
        timeout: Seconds to wait for the user to respond to the system prompt.

    Returns:
        True if access was granted, False otherwise.
    """
    result = {"granted": False}
    done = threading.Event()

    def completion(granted, error):
        result["granted"] = bool(granted)
        if error is not None:
            print(f"Calendar access error: {error}", file=sys.stderr)
        done.set()

    if hasattr(store, "requestFullAccessToEventsWithCompletion_"):
        store.requestFullAccessToEventsWithCompletion_(completion)
    else:
        store.requestAccessToEntityType_completion_(EKEntityTypeEvent, completion)

    done.wait(timeout=timeout)
    return result["granted"]


def fetch_events(
    store: EKEventStore,
    start_dt: datetime,
    end_dt: datetime,
    calendar_filter: list[str] | None = None,
) -> list[AnonymizedEvent]:
    """Load events in [start_dt, end_dt] and reduce to AnonymizedEvent.

    Args:
        store:           An authorized `EKEventStore` instance.
        start_dt:        Inclusive window start (local datetime).
        end_dt:          Inclusive window end (local datetime).
        calendar_filter: Optional list of case insensitive substrings.
                         A calendar is included if any substring matches its title.

    Returns:
        List of `AnonymizedEvent`. Only structural metadata is loaded.
    """
    start_ns = NSDate.dateWithTimeIntervalSince1970_(start_dt.timestamp())
    end_ns = NSDate.dateWithTimeIntervalSince1970_(end_dt.timestamp())

    calendars = list(store.calendarsForEntityType_(EKEntityTypeEvent))
    if calendar_filter:
        needles = [c.lower() for c in calendar_filter]
        calendars = [
            c for c in calendars
            if any(n in c.title().lower() for n in needles)
        ]
        if not calendars:
            print("No calendars matched the filter.", file=sys.stderr)
            return []

    predicate = store.predicateForEventsWithStartDate_endDate_calendars_(
        start_ns, end_ns, calendars,
    )
    raw = store.eventsMatchingPredicate_(predicate)

    events: list[AnonymizedEvent] = []
    for ev in raw:
        events.append(AnonymizedEvent(
            start=datetime.fromtimestamp(ev.startDate().timeIntervalSince1970()),
            end=datetime.fromtimestamp(ev.endDate().timeIntervalSince1970()),
            calendar=str(ev.calendar().title()),
            all_day=bool(ev.isAllDay()),
        ))
    return events
