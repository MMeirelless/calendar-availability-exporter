# Examples

## Weekly automated export with launchd

`weekly_export.sh` is a wrapper that computes the current week's Monday and Friday, then runs the tool. Use a launchd agent to run it on a schedule.

### 1. Make the wrapper executable

```bash
chmod +x examples/weekly_export.sh
```

Edit the script to set:
- `PYTHON_BIN`: full path to the Python interpreter where the package is installed.
- `OUTPUT_DIR`: where the PNG should land.
- Optional flags: `--calendars`, `--lunch`, `--no-times`.

### 2. Create a launchd agent

Save the following as `~/Library/LaunchAgents/local.calendar-availability.plist`. Adjust the path to `weekly_export.sh`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.calendar-availability</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOU/projects/calendar-availability-export/examples/weekly_export.sh</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>22</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/tmp/calendar-availability.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/calendar-availability.err</string>
</dict>
</plist>
```

`Weekday=0` is Sunday, so the job runs Sunday at 22:00 local time and produces a fresh PNG for the upcoming week.

### 3. Load the agent

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.calendar-availability.plist
```

To unload:

```bash
launchctl bootout gui/$(id -u)/local.calendar-availability
```

To trigger immediately for testing:

```bash
launchctl kickstart -k gui/$(id -u)/local.calendar-availability
```

### Notes

The script and the Python interpreter both need Calendar access. The first run will surface the prompt. If launchd runs it before you have granted access interactively, the run will fail. Run the script manually from Terminal once, approve the prompt, then enable the agent.
