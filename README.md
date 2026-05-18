# calendar-availability-export

Export an anonymized weekly availability view from macOS Calendar.app using EventKit. Share your schedule without leaking event titles, attendees, notes, or locations.

> **Status:** v0.1.0, macOS only. Tested on Python 3.10+ and macOS 14/15.

## Why this exists

When someone asks *"when are you free next week?"*, the usual options are:

1. Maintain a written list of free slots: tedious and easy to desync.
2. Share your full calendar: leaks confidential meeting details.
3. Screenshot Calendar.app and manually black out titles: fragile and slow.

This tool takes a different path. It reads only the structural metadata of your events (start time, end time, source calendar, all-day flag) and renders a fresh image from that. Event titles, descriptions, attendees, and locations are never loaded into memory in the first place, so there is nothing to redact.

## How it works

1. Connects to EventKit through PyObjC, using the same Apple framework Calendar.app itself uses.
2. Loads only start, end, calendar name, and the all-day flag for each event in the requested window.
3. Renders a dark themed weekly grid with matplotlib. Blocks are colored by calendar. Time labels are optional.
4. Outputs a PNG ready to share over Slack, email, or anywhere else.

Recurring events are expanded automatically by EventKit. Calendar names are masked to generic labels (`Calendar 1`, `Calendar 2`) in the legend so even the calendar inventory is not disclosed.

## Anonymization model

The data flow is deliberately narrow. The `AnonymizedEvent` dataclass exposes exactly four fields:

| Field | Type | Purpose |
|-------|------|---------|
| `start` | `datetime` | When the event begins |
| `end` | `datetime` | When the event ends |
| `calendar` | `str` | Used only for color grouping |
| `all_day` | `bool` | Render as a top strip instead of a block |

Title, notes, location, attendees, URLs, and attachments are never read from the EventKit objects. They cannot end up in logs, debug output, swap, or the rendered PNG because they are never loaded.

This is anonymization by construction, not by post-hoc redaction.

## Requirements

- macOS 11 (Big Sur) or later
- Python 3.10 or newer
- A Calendar.app account with at least one calendar configured

## Installation

Use a project local virtual environment. Conda's `base` environment mixes pip and conda state and can produce ABI mismatches between matplotlib and NumPy.

```bash
git clone https://github.com/mb2analytics/calendar-availability-export.git
cd calendar-availability-export
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
```

If you do not want to install the package, the script also runs as a module after dependencies are installed:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m calendar_availability --help
```

### Anaconda users

If you are on anaconda, prefer a dedicated env over `base`:

```bash
conda create -n cal-availability python=3.12 -y
conda activate cal-availability
pip install -e .
```

### Troubleshooting matplotlib

If you see `_ARRAY_API not found` or `numpy.core.multiarray failed to import`, matplotlib was compiled against NumPy 1.x and your environment has NumPy 2.x. matplotlib 3.9 is the first release with NumPy 2 support. Upgrade matplotlib inside your active env:

```bash
pip install -U "matplotlib>=3.9"
```

This is the symptom you get when running directly inside Anaconda's `base` without a fresh env.

## First run: grant Calendar access

On the first run, macOS displays a permission prompt for Calendar access. Approve it.

If you run the tool from Terminal, Terminal itself also needs Calendar access. You can verify or grant it manually in:

```
System Settings > Privacy & Security > Calendars
```

If access is revoked or denied, the tool exits with a clear message pointing to the same path.

## Usage

Basic week export:

```bash
calendar-availability \
  --start 2026-05-18 \
  --end   2026-05-22 \
  --day-start 09:00 \
  --day-end   20:00 \
  --output availability.png
```

Filter to specific calendars (case insensitive substring match):

```bash
calendar-availability \
  --start 2026-05-18 --end 2026-05-22 \
  --calendars "Work,Personal"
```

Add a lunch overlay:

```bash
calendar-availability \
  --start 2026-05-18 --end 2026-05-22 \
  --lunch 12:00-14:00
```

Maximum anonymization (hide event time labels, only show colored blocks):

```bash
calendar-availability \
  --start 2026-05-18 --end 2026-05-22 \
  --no-times
```

Run as a module without installing the entry point:

```bash
python -m calendar_availability --start 2026-05-18 --end 2026-05-22
```

## Configuration reference

| Flag | Default | Description |
|------|---------|-------------|
| `--start` | required | First day of the window (`YYYY-MM-DD`) |
| `--end` | required | Last day of the window (`YYYY-MM-DD`) |
| `--day-start` | `09:00` | First visible hour |
| `--day-end` | `20:00` | Last visible hour |
| `--output` | `availability.png` | Output PNG path |
| `--calendars` | all | Comma separated calendar name substrings to include |
| `--lunch` | none | Lunch overlay window, e.g. `12:00-14:00` |
| `--no-times` | off | Hide `HH:MM` labels inside event blocks |

## Project structure

```
calendar-availability-export/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── pyproject.toml
├── requirements.txt
├── Makefile
├── .gitignore
├── .editorconfig
├── src/
│   └── calendar_availability/
│       ├── __init__.py           # Package init, version, public API
│       ├── __main__.py           # Enables `python -m calendar_availability`
│       ├── cli.py                # argparse, validates input, orchestrates
│       ├── eventkit_client.py    # EventKit access, permission handling
│       ├── models.py             # AnonymizedEvent dataclass (anonymization boundary)
│       ├── render.py             # matplotlib rendering
│       └── theme.py              # Color palette constants
├── examples/
│   ├── README.md
│   └── weekly_export.sh          # Wrapper used by launchd
├── tests/
│   ├── __init__.py
│   └── test_models.py            # Asserts AnonymizedEvent stays minimal
└── docs/
    └── (screenshots)
```

## Automating weekly exports

A shell wrapper plus a launchd agent is the cleanest way to regenerate the current week on a schedule. See [`examples/weekly_export.sh`](examples/weekly_export.sh) and the launchd snippet in [`examples/README.md`](examples/README.md).

For ad hoc automation in your existing pipelines, the same modules expose a Python API:

```python
from datetime import date, datetime, time
from pathlib import Path
from EventKit import EKEventStore

from calendar_availability import fetch_events, render
from calendar_availability.eventkit_client import request_calendar_access

store = EKEventStore.alloc().init()
if not request_calendar_access(store):
    raise SystemExit("Calendar access denied")

events = fetch_events(
    store,
    datetime(2026, 5, 18, 0, 0),
    datetime(2026, 5, 22, 23, 59),
    calendar_filter=["Work"],
)

render(
    events=events,
    start_date=date(2026, 5, 18),
    end_date=date(2026, 5, 22),
    day_start=time(9, 0),
    day_end=time(20, 0),
    lunch=(time(12, 0), time(14, 0)),
    output_path=Path("availability.png"),
    show_times=True,
)
```

## Development

```bash
make install    # Editable install with dev dependencies
make lint       # ruff check
make format     # ruff format
make test       # pytest
make clean      # Remove build artifacts and caches
```

## Roadmap

- ICS file fallback for non-macOS systems (read exported `.ics` instead of EventKit)
- SVG output for vector sharing
- Configurable timezone display for cross-region scheduling
- `--free` inverse mode that highlights free slots instead of busy slots
- Microsoft 365 backend (read availability from Outlook directly)
- Multi-week view (4 week strip for longer planning horizons)

## License

MIT. See [LICENSE](LICENSE).

## Maintainer

Built and maintained by [MB2 Analytics](https://mb2analytics.com).
