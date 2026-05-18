# Calendar Availability — Mac App

Native SwiftUI front-end for the [calendar-availability-exporter](../) project. Renders the same anonymized weekly availability chart as the Python CLI, with a Liquid Glass UI and one-click clipboard export.

## Requirements

- **macOS 26 Tahoe** — Liquid Glass is a Tahoe feature; nothing older will compile against the required APIs.
- **Xcode 26** — ships the macOS 26 SDK. Install free from the App Store, then:
  ```sh
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```

The Command Line Tools alone are **not** sufficient — they ship the macOS 15 SDK at most.

## Build & run

```sh
cd macapp
./build.sh
open "build/Calendar Availability.app"
```

`build.sh` invokes `swift build -c release`, assembles the `.app` bundle, and codesigns it ad-hoc so it launches on Apple Silicon.

On first launch macOS prompts for Calendar access — required to read event times. The app reads only `start`, `end`, calendar title, and `isAllDay`. Titles, attendees, notes, and locations are never accessed (same anonymization boundary as the Python `AnonymizedEvent`).

## Usage

1. Pick a week with the prev / Today / next buttons in the sidebar.
2. Tune the day range, lunch overlay, calendar filter, and "Hide event times" toggle. The chart in the main pane updates live.
3. Hit **Generate & Copy** (⌘↩) — the chart is rendered at 3600×2200 and copied to the clipboard. Paste anywhere.
4. **Save as PNG…** (⌘S) — opens a save panel and also copies to the clipboard.

## Project layout

```
macapp/
├── Package.swift                       # SwiftPM manifest, macOS 26 target
├── Info.plist                          # Bundle metadata + Calendar usage description
├── CalendarAvailability.entitlements   # (empty; non-sandboxed for local use)
├── build.sh                            # swift build → .app bundle → ad-hoc codesign
└── Sources/CalendarAvailability/
    ├── CalendarAvailabilityApp.swift   # @main App scene
    ├── ContentView.swift               # NavigationSplitView + toast overlay
    ├── Theme.swift                     # Catppuccin Mocha palette
    ├── Models/
    │   ├── AnonymizedEvent.swift       # Mirrors the Python anonymization boundary
    │   └── AvailabilityOptions.swift   # @Observable model bound to the UI
    ├── Services/
    │   ├── CalendarService.swift       # EventKit access + fetch
    │   └── Exporter.swift              # ImageRenderer → NSImage → clipboard / disk
    └── Views/
        ├── Sidebar.swift               # Glass sidebar with controls + action bar
        ├── ChartArea.swift             # Main chart pane + permission overlays
        ├── AvailabilityChart.swift     # Canvas renderer (matches render.py)
        └── CalendarFilterList.swift    # Multi-select calendar toggles
```

## Notes on Liquid Glass

The app uses native macOS 26 APIs:

- `NavigationSplitView` — sidebar gets the system Liquid Glass material automatically in Tahoe.
- `.buttonStyle(.glassProminent)` — primary "Generate & Copy" action.
- `.buttonStyle(.glass)` — secondary buttons (week nav, Save).
- `.glassEffect(.regular, in: .capsule)` — the floating toast notification.
- `.glassEffect(.regular, in: .rect(cornerRadius: 18))` — permission status overlays.

If you build on a pre-Tahoe SDK these modifiers will not resolve. The `build.sh` preflight check catches that and refuses to build.
