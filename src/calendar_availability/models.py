"""Data models for the project.

This module defines the anonymization boundary. The `AnonymizedEvent` dataclass
intentionally exposes only the four fields required to render an availability
view. Titles, notes, attendees, locations, URLs, and attachments are never
represented here and are never read from EventKit. This is anonymization by
construction.

If you add a field here, you are widening the data flow. Do it deliberately.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class AnonymizedEvent:
    """A single event reduced to time and calendar membership.

    Attributes:
        start:    Event start time (local time).
        end:      Event end time (local time).
        calendar: Source calendar title, used only for color grouping.
        all_day:  True if the event is marked as all-day in Calendar.app.
    """

    start: datetime
    end: datetime
    calendar: str
    all_day: bool

    @property
    def duration_minutes(self) -> float:
        """Convenience: event duration in minutes."""
        return (self.end - self.start).total_seconds() / 60
