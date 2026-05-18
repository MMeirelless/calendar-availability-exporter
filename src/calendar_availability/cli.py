"""CLI entry point.

Parses arguments, requests Calendar access, fetches anonymized events,
and renders the weekly view.
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, time
from pathlib import Path

from EventKit import EKEventStore

from . import __version__
from .eventkit_client import fetch_events, request_calendar_access
from .render import render


def _parse_time(s: str) -> time:
    h, m = s.split(":")
    return time(int(h), int(m))


def _parse_lunch(s: str | None) -> tuple[time, time] | None:
    if not s:
        return None
    a, b = s.split("-")
    return _parse_time(a), _parse_time(b)


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="calendar-availability",
        description="Export anonymized weekly availability from macOS Calendar.app.",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    parser.add_argument("--start",     required=True, help="Start date YYYY-MM-DD")
    parser.add_argument("--end",       required=True, help="End date YYYY-MM-DD")
    parser.add_argument("--day-start", default="09:00", help="Day start HH:MM (default 09:00)")
    parser.add_argument("--day-end",   default="20:00", help="Day end HH:MM (default 20:00)")
    parser.add_argument("--output",    default="availability.png", help="Output PNG path")
    parser.add_argument(
        "--calendars",
        help="Comma separated calendar name substrings to include (case insensitive)",
    )
    parser.add_argument("--lunch", help="Lunch overlay window, e.g. 12:00-14:00")
    parser.add_argument(
        "--no-times", action="store_true",
        help="Hide start/end labels inside blocks for maximum anonymization",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    start_d = datetime.strptime(args.start, "%Y-%m-%d").date()
    end_d = datetime.strptime(args.end, "%Y-%m-%d").date()
    if end_d < start_d:
        print("--end must be on or after --start", file=sys.stderr)
        return 2

    day_start = _parse_time(args.day_start)
    day_end = _parse_time(args.day_end)
    lunch = _parse_lunch(args.lunch)
    calendar_filter = (
        [c.strip() for c in args.calendars.split(",")] if args.calendars else None
    )

    store = EKEventStore.alloc().init()
    if not request_calendar_access(store):
        print(
            "Calendar access not granted. Open System Settings > Privacy & Security > "
            "Calendars and enable access for your Python interpreter (and Terminal).",
            file=sys.stderr,
        )
        return 1

    start_dt = datetime.combine(start_d, time(0, 0))
    end_dt = datetime.combine(end_d, time(23, 59, 59))

    events = fetch_events(store, start_dt, end_dt, calendar_filter)
    print(f"Loaded {len(events)} events in {(end_d - start_d).days + 1} day window")

    out = Path(args.output)
    render(
        events=events,
        start_date=start_d,
        end_date=end_d,
        day_start=day_start,
        day_end=day_end,
        output_path=out,
        lunch=lunch,
        show_times=not args.no_times,
    )
    print(f"Wrote {out.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
