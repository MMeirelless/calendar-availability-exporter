# Calendar Availability — Mac App

Native SwiftUI front-end for the [calendar-availability-exporter](../) project. Renders the same anonymized weekly availability chart as the Python CLI, with a Liquid Glass UI and one-click clipboard export.

## Download a prebuilt .app

Every push to `main` that touches `macapp/` triggers a GitHub Actions build that publishes a release. Grab the latest `.zip` from the [Releases page](../../../releases/latest), unzip, drag into `/Applications`, and **right-click → Open** the first time (ad-hoc signed, not notarized).

## Requirements

- **macOS 26 Tahoe** — Liquid Glass is a Tahoe feature; nothing older will compile against the required APIs.
- **Xcode 26** — ships the macOS 26 SDK. Install free from the App Store, then:
  ```sh
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```

The Command Line Tools alone are **not** sufficient — they ship the macOS 15 SDK at most.

## App icon

Drop a 1024×1024 PNG at `macapp/Resources/AppIcon.png` and `build.sh` will auto-generate `AppIcon.icns` (via `sips` + `iconutil`) and embed it in the bundle on the next build. A neutral placeholder is checked in — replace it with your own design.

## Build & run

```sh
cd macapp
./build.sh
open "build/Calendar Availability.app"
```

`build.sh` invokes `swift build -c release`, assembles the `.app` bundle, and codesigns it ad-hoc so it launches on Apple Silicon.

On first launch macOS prompts for Calendar access — required to read event times. The app reads only `start`, `end`, calendar title, and `isAllDay`. Titles, attendees, notes, and locations are never accessed (same anonymization boundary as the Python `AnonymizedEvent`).

## Install to /Applications

To use the app daily (and find it via Finder / Spotlight / Launchpad), copy the built bundle into `/Applications`:

```sh
./build.sh && ./install.sh
```

`install.sh` quits any running instance, replaces `/Applications/Calendar Availability.app`, and strips the quarantine attribute. Re-run it after any rebuild to refresh your daily-use install.

Note: every ad-hoc rebuild produces a fresh code signature, so macOS may prompt for Calendar access again after `install.sh` — re-grant once and you're done.

## Usage

1. Pick a week with the prev / Today / next buttons in the sidebar.
2. Choose a **Timezone** — defaults to the system timezone, shown as a subtitle on the chart. The visible ISO week is re-anchored when you switch so the same Mon–Sun stays in view.
3. Tune the day range, lunch overlay, calendar filter, "Include weekends," and "Hide event times" toggles. The chart updates live.
4. In the **Event Types** section, pick which availability classes to draw — Busy, Tentative, Free, Unavailable. Free is off by default so events you've explicitly marked Free in Calendar.app don't bleed into the "blocked time" screenshot, but you can toggle it on.
5. Hit **Generate & Copy** (⌘↩) — the chart is rendered at 3600×2200 and copied to the clipboard. Paste anywhere.
6. **Save as PNG…** (⌘S) — opens a save panel and also copies to the clipboard.

Each availability class gets its own color **and** texture so the screenshot is unambiguous even in greyscale or for colorblind viewers:

- **Busy** — solid pink fill.
- **Tentative** — yellow fill with diagonal stripes.
- **Free** — green dashed outline, faded fill (signals "the event exists but doesn't actually block").
- **Unavailable** — mauve fill with cross-hatching.

The legend at the bottom-right renders each visible class with the same fill + texture so it acts as a faithful key to whatever appears on the chart.

## Project layout

```
macapp/
├── Package.swift                       # SwiftPM manifest, macOS 26 target
├── Info.plist                          # Bundle metadata + Calendar usage description
├── CalendarAvailability.entitlements   # (empty; non-sandboxed for local use)
├── build.sh                            # swift build → .app bundle → ad-hoc codesign
├── install.sh                          # Copy bundle into /Applications
├── Resources/
│   └── AppIcon.png                     # 1024×1024 source for the app icon
└── Sources/CalendarAvailability/
    ├── CalendarAvailabilityApp.swift   # @main App scene
    ├── ContentView.swift               # NavigationSplitView + toast overlay
    ├── Theme.swift                     # Catppuccin Mocha palette
    ├── Models/
    │   ├── AnonymizedEvent.swift       # Mirrors the Python anonymization boundary
    │   ├── AvailabilityOptions.swift   # @Observable model bound to the UI
    │   ├── EventAvailability.swift     # busy / tentative / free / unavailable enum
    │   └── TimeZones.swift             # Common + all-IANA timezone helpers
    ├── Services/
    │   ├── CalendarService.swift       # EventKit access + fetch
    │   └── Exporter.swift              # ImageRenderer → NSImage → clipboard / disk
    └── Views/
        ├── Sidebar.swift               # Glass sidebar with controls + action bar
        ├── ChartArea.swift             # Main chart pane + permission overlays
        ├── AvailabilityChart.swift     # Canvas renderer (single-color, legend)
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
