import SwiftUI

struct Sidebar: View {
    @Environment(AvailabilityOptions.self) private var options
    @Environment(CalendarService.self) private var service

    let onGenerate: () -> Void
    let onSave: () -> Void

    var body: some View {
        @Bindable var options = options

        VStack(spacing: 0) {
            Form {
                Section("Week") {
                    weekRow
                }

                Section("Timezone") {
                    timezonePicker
                }

                Section("Day Range") {
                    hourStepper(label: "Start", value: $options.dayStartHour, range: 0...23)
                    hourStepper(label: "End",   value: $options.dayEndHour,   range: 1...24)
                }

                Section("Lunch Overlay") {
                    Toggle("Show lunch band", isOn: $options.lunchEnabled)
                    if options.lunchEnabled {
                        hourStepper(label: "Start", value: $options.lunchStartHour, range: 0...23)
                        hourStepper(label: "End",   value: $options.lunchEndHour,   range: 1...24)
                    }
                }

                Section("Display") {
                    Toggle("Include weekends", isOn: $options.includeWeekends)
                    Toggle("Hide event times", isOn: $options.hideEventTimes)
                }

                Section("Calendars") {
                    CalendarFilterList()
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            actionBar
        }
    }

    // MARK: - Week row

    private var weekRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(options.weekISOLabel)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .monospacedDigit()

            Text(weekRangeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button {
                    options.step(weeks: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .help("Previous week")

                Button {
                    options.resetToCurrentWeek()
                } label: {
                    Text("Today")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)

                Button {
                    options.step(weeks: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .help("Next week")
            }
            .controlSize(.regular)
        }
        .padding(.vertical, 2)
    }

    private var weekRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.timeZone = options.timezone
        let start = f.string(from: options.weekStart)
        let end = f.string(from: options.weekEnd)
        return "\(start) – \(end)"
    }

    // MARK: - Timezone picker

    private var timezonePicker: some View {
        @Bindable var options = options
        return Picker(selection: $options.timezone) {
            Section("Common") {
                ForEach(TimeZones.common, id: \.identifier) { tz in
                    Text(TimeZones.displayName(tz)).tag(tz)
                }
            }
            Section("All") {
                ForEach(TimeZones.all, id: \.identifier) { tz in
                    Text(TimeZones.displayName(tz)).tag(tz)
                }
            }
        } label: {
            HStack {
                Text("Zone")
                Spacer()
                Text(TimeZones.gmtOffsetLabel(options.timezone))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .pickerStyle(.menu)
    }

    // MARK: - Hour stepper

    @ViewBuilder
    private func hourStepper(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%02d:00", value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Action bar

    private var actionBar: some View {
        VStack(spacing: 10) {
            Button(action: onGenerate) {
                Label("Generate & Copy", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Render the chart and copy it to the clipboard (⌘↩)")

            Button(action: onSave) {
                Label("Save as PNG…", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.regular)
            .keyboardShortcut("s", modifiers: [.command])
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }
}
