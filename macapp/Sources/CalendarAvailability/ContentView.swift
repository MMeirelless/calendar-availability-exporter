import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(CalendarService.self) private var service
    @Environment(AvailabilityOptions.self) private var options

    @State private var events: [AnonymizedEvent] = []
    @State private var toast: Toast?

    struct Toast: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String?
    }

    var body: some View {
        NavigationSplitView {
            Sidebar(
                onGenerate: handleGenerate,
                onSave: handleSave
            )
            .navigationSplitViewColumnWidth(min: 300, ideal: 330, max: 400)
        } detail: {
            ChartArea(events: events)
                .overlay(alignment: .top) { toastView }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear(perform: reloadIfPossible)
        .onChange(of: service.status) { _, _ in
            seedSelectionIfNeeded()
            reloadIfPossible()
        }
        .onChange(of: options.weekStart) { _, _ in reloadIfPossible() }
        .onChange(of: options.selectedCalendarIDs) { _, _ in reloadIfPossible() }
    }

    // MARK: - Data flow

    private func seedSelectionIfNeeded() {
        guard options.selectedCalendarIDs.isEmpty else { return }
        options.selectedCalendarIDs = Set(service.calendars.map { $0.calendarIdentifier })
    }

    private func reloadIfPossible() {
        guard service.status == .granted else { return }
        let (start, end) = options.fetchWindow
        events = service.fetchEvents(
            start: start,
            end: end,
            calendarIDs: options.selectedCalendarIDs
        )
    }

    // MARK: - Actions

    private func handleGenerate() {
        guard let image = Exporter.renderImage(
            events: events,
            options: options
        ) else {
            showToast(icon: "xmark.octagon.fill",
                      title: "Couldn't render image",
                      subtitle: nil)
            return
        }
        Exporter.copyToClipboard(image)
        showToast(
            icon: "checkmark.circle.fill",
            title: "Copied to clipboard",
            subtitle: "\(options.weekISOLabel) • paste anywhere"
        )
    }

    private func handleSave() {
        guard let image = Exporter.renderImage(
            events: events,
            options: options
        ) else { return }
        let suggested = "availability_\(options.weekISOLabel)"
        if let url = Exporter.savePNG(image: image, suggestedName: suggested) {
            // Also copy to clipboard on save, so the workflow is consistent.
            Exporter.copyToClipboard(image)
            showToast(
                icon: "square.and.arrow.down.fill",
                title: "Saved & copied",
                subtitle: url.lastPathComponent
            )
        }
    }

    // MARK: - Toast

    private func showToast(icon: String, title: String, subtitle: String?) {
        let t = Toast(icon: icon, title: title, subtitle: subtitle)
        toast = t
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            if toast?.id == t.id {
                withAnimation(.easeOut(duration: 0.25)) { toast = nil }
            }
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            HStack(spacing: 12) {
                Image(systemName: toast.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 1) {
                    Text(toast.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    if let sub = toast.subtitle {
                        Text(sub)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular, in: .capsule)
            .padding(.top, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
