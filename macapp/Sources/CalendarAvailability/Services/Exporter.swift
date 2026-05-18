import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Renders the availability chart to an NSImage and handles the
/// "Generate" pipeline: copy to clipboard (always), optional save to disk.
@MainActor
enum Exporter {

    /// Output size for the rendered PNG. 1800×1100 at 2× scale produces
    /// a 3600×2200 image — large enough to drop into Slack/Notion/email
    /// without visible loss, and still well below typical paste limits.
    static let outputSize = CGSize(width: 1800, height: 1100)
    static let outputScale: CGFloat = 2.0

    /// Renders the chart at high resolution and returns the NSImage.
    static func renderImage(
        events: [AnonymizedEvent],
        options: AvailabilityOptions
    ) -> NSImage? {
        let chart = AvailabilityChart(
            events: events,
            weekStart: options.weekStart,
            dayStartHour: options.dayStartHour,
            dayEndHour: options.dayEndHour,
            lunch: options.lunchEnabled
                ? (options.lunchStartHour, options.lunchEndHour)
                : nil,
            showTimes: !options.hideEventTimes,
            timezone: options.timezone
        )
        .frame(width: outputSize.width, height: outputSize.height)
        .background(Theme.bg)

        let renderer = ImageRenderer(content: chart)
        renderer.scale = outputScale
        renderer.isOpaque = true
        return renderer.nsImage
    }

    /// Encodes an NSImage as PNG data.
    static func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    /// Copies the image to the general pasteboard in both PNG and TIFF form
    /// so paste targets that prefer one or the other (Slack, Mail, Notes,
    /// Finder, iMessage) all work.
    static func copyToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()

        let item = NSPasteboardItem()
        if let png = pngData(from: image) {
            item.setData(png, forType: .png)
        }
        if let tiff = image.tiffRepresentation {
            item.setData(tiff, forType: .tiff)
        }
        pb.writeObjects([item])
    }

    /// Opens an NSSavePanel and writes PNG to the chosen location.
    /// Returns the URL written, or nil if cancelled / failed.
    static func savePNG(image: NSImage, suggestedName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "\(suggestedName).png"
        panel.canCreateDirectories = true
        panel.title = "Save Availability"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard let data = pngData(from: image) else { return nil }
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
