import SwiftUI

struct CalendarFilterList: View {
    @Environment(CalendarService.self) private var service
    @Environment(AvailabilityOptions.self) private var options

    var body: some View {
        if service.calendars.isEmpty {
            Text("No calendars available")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(service.calendars, id: \.calendarIdentifier) { cal in
                row(for: cal.title, id: cal.calendarIdentifier)
            }
        }
    }

    private func row(for title: String, id: String) -> some View {
        let idx = service.paletteIndex(for: title)
        let color = Theme.palette[idx % Theme.palette.count]
        let isOn = Binding(
            get: { options.selectedCalendarIDs.contains(id) },
            set: { on in
                if on { options.selectedCalendarIDs.insert(id) }
                else  { options.selectedCalendarIDs.remove(id) }
            }
        )

        return Toggle(isOn: isOn) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }
}
