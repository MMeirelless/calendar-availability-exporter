import SwiftUI

struct Sidebar: View {
    @Environment(AvailabilityOptions.self) private var options
    @Environment(CalendarService.self) private var service

    let onGenerate: () -> Void
    let onSave: () -> Void

    @State private var showResetConfirm = false

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

                Section {
                    ForEach(EventAvailability.ordered) { avail in
                        Toggle(isOn: availabilityBinding(for: avail)) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Theme.color(for: avail))
                                    .frame(width: 10, height: 10)
                                Text(avail.displayName)
                            }
                        }
                    }
                } header: {
                    Text("Event Types")
                } footer: {
                    Text("Pick which availability classes appear on the chart. Events marked Free are hidden by default.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Section("Calendars") {
                    CalendarFilterList()
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset all settings", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Restore every option above to its default. Does not affect your calendar data.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .confirmationDialog(
                "Reset all settings to defaults?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    options.resetToDefaults()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Day range, lunch overlay, timezone, calendar selection, event-type filters, and other display options return to their defaults.")
            }

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

    // MARK: - Availability toggle binding

    /// Binds a single EventAvailability case to membership in the
    /// `visibleAvailabilities` set so a `Toggle` can drive it directly.
    private func availabilityBinding(for avail: EventAvailability) -> Binding<Bool> {
        Binding(
            get: { options.visibleAvailabilities.contains(avail) },
            set: { isOn in
                if isOn {
                    options.visibleAvailabilities.insert(avail)
                } else {
                    options.visibleAvailabilities.remove(avail)
                }
            }
        )
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
