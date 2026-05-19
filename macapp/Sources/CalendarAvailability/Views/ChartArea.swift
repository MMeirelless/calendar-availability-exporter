import AppKit
import SwiftUI

struct ChartArea: View {
    let events: [AnonymizedEvent]

    @Environment(AvailabilityOptions.self) private var options
    @Environment(CalendarService.self) private var service

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            switch service.status {
            case .granted:
                chart
            case .unknown, .requesting:
                requestingOverlay
            case .denied:
                deniedOverlay
            case .error(let msg):
                errorOverlay(msg)
            }
        }
    }

    // MARK: - Chart

    private var chart: some View {
        AvailabilityChart(
            events: events,
            weekStart: options.weekStart,
            dayStartHour: options.dayStartHour,
            dayEndHour: options.dayEndHour,
            lunch: options.lunchEnabled
                ? (options.lunchStartHour, options.lunchEndHour)
                : nil,
            showTimes: !options.hideEventTimes,
            includeWeekends: options.includeWeekends,
            timezone: options.timezone,
            visibleAvailabilities: options.visibleAvailabilities
        )
        .padding(20)
    }

    // MARK: - Status overlays

    private var requestingOverlay: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Requesting Calendar access…")
                .font(.headline)
                .foregroundStyle(Theme.text)
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private var deniedOverlay: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 34))
                .foregroundStyle(Theme.lunch)
            Text("Calendar access required")
                .font(.headline)
                .foregroundStyle(Theme.text)
            Text("Open System Settings → Privacy & Security → Calendars and enable access for Calendar Availability.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .padding(32)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func errorOverlay(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange)
            Text("Couldn't access Calendar")
                .font(.headline)
                .foregroundStyle(Theme.text)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}
