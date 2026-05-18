"""Tests for the anonymization boundary.

The whole privacy story of this tool rests on AnonymizedEvent exposing only
four fields. These tests fail loudly if anyone widens the dataclass.
"""

from __future__ import annotations

import dataclasses
from datetime import datetime

import pytest

from calendar_availability.models import AnonymizedEvent


def _sample_event() -> AnonymizedEvent:
    return AnonymizedEvent(
        start=datetime(2026, 5, 18, 9, 0),
        end=datetime(2026, 5, 18, 10, 0),
        calendar="Work",
        all_day=False,
    )


def test_anonymized_event_has_only_expected_fields():
    expected = {"start", "end", "calendar", "all_day"}
    actual = {f.name for f in dataclasses.fields(AnonymizedEvent)}
    assert actual == expected, (
        f"AnonymizedEvent fields changed. Expected {expected}, got {actual}. "
        "Widening this dataclass weakens the anonymization guarantee."
    )


def test_anonymized_event_is_frozen():
    ev = _sample_event()
    with pytest.raises(dataclasses.FrozenInstanceError):
        ev.calendar = "Leaked"  # type: ignore[misc]


def test_duration_minutes():
    ev = _sample_event()
    assert ev.duration_minutes == 60


def test_no_sensitive_attrs():
    """Sanity check: instances must not carry title/notes/attendees/location."""
    ev = _sample_event()
    for forbidden in ("title", "notes", "attendees", "location", "url", "summary"):
        assert not hasattr(ev, forbidden), (
            f"AnonymizedEvent gained a `{forbidden}` attribute. "
            "Remove it to preserve the anonymization boundary."
        )
