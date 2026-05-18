"""Export anonymized weekly availability from macOS Calendar.app via EventKit.

Public API:
    AnonymizedEvent: dataclass holding only structural event metadata
    fetch_events:    load events in a window, reduced to AnonymizedEvent
    render:          render a weekly grid to PNG

The EventKit-dependent symbols (`fetch_events`, `render`) are lazily loaded
so this package can be imported on non-macOS systems for testing or
introspection of the data model.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from .models import AnonymizedEvent

__version__ = "0.1.0"
__all__ = ["AnonymizedEvent", "fetch_events", "render", "__version__"]


if TYPE_CHECKING:
    from .eventkit_client import fetch_events  # noqa: F401
    from .render import render                 # noqa: F401


def __getattr__(name: str):
    """Lazily resolve EventKit and matplotlib backed symbols.

    Keeps `from calendar_availability.models import AnonymizedEvent` working
    on systems where PyObjC or matplotlib is not installed.
    """
    if name == "fetch_events":
        from .eventkit_client import fetch_events
        return fetch_events
    if name == "render":
        from .render import render
        return render
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
