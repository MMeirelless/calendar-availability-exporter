import SwiftUI

/// The availability grid. Mirrors the spirit of the Python renderer.
/// Events are colored by their EKEventAvailability class (busy /
/// tentative / free / unavailable), and the user picks which classes
/// to draw via `visibleAvailabilities`. The legend at the bottom-right
/// shows one row per visible class so the screenshot reads correctly
/// without the viewer needing context.
struct AvailabilityChart: View {
    let events: [AnonymizedEvent]
    let weekStart: Date
    let dayStartHour: Int
    let dayEndHour: Int
    let lunch: (start: Int, end: Int)?
    let showTimes: Bool
    let includeWeekends: Bool
    let timezone: TimeZone
    let visibleAvailabilities: Set<EventAvailability>

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            draw(context: &context, size: size)
        }
        .background(Theme.bg)
    }

    // MARK: - Drawing

    private func draw(context: inout GraphicsContext, size: CGSize) {
        let cal = isoCalendar
        let dayCount = includeWeekends ? 7 : 5
        let days: [Date] = (0..<dayCount).compactMap {
            cal.date(byAdding: .day, value: $0, to: weekStart)
        }
        guard days.count == dayCount else { return }

        let dayStartH = Double(dayStartHour)
        let dayEndH = Double(dayEndHour)
        let totalHours = max(dayEndH - dayStartH, 1)

        // --- Layout --------------------------------------------------------
        let padding: CGFloat = 24
        let titleHeight: CGFloat = 22
        let subtitleHeight: CGFloat = 18
        let headerHeight: CGFloat = 44
        let leftAxis: CGFloat = 56
        let bottomPad: CGFloat = 16

        let chartX = padding + leftAxis
        let chartY = padding + titleHeight + subtitleHeight + headerHeight
        let chartWidth = size.width - chartX - padding
        let chartHeight = size.height - chartY - bottomPad
        let colWidth = chartWidth / CGFloat(dayCount)

        guard chartWidth > 50, chartHeight > 50 else { return }

        // --- Title + timezone subtitle ------------------------------------
        let titleFmt = dateFormatter("EEE MMM d")
        let titleEndFmt = dateFormatter("EEE MMM d, yyyy")
        let title = "Availability: \(titleFmt.string(from: days.first!)) to \(titleEndFmt.string(from: days.last!))"

        context.draw(
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text),
            at: CGPoint(x: padding, y: padding + titleHeight / 2),
            anchor: .leading
        )

        let tzLabel = "\(timezone.identifier) • \(TimeZones.gmtOffsetLabel(timezone))"
        context.draw(
            Text(tzLabel)
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted),
            at: CGPoint(x: padding, y: padding + titleHeight + subtitleHeight / 2),
            anchor: .leading
        )

        // --- Day headers ---------------------------------------------------
        let dayHeaderFmt = dateFormatter("EEE")
        let daySubFmt = dateFormatter("MMM d")
        for (i, d) in days.enumerated() {
            let cx = chartX + CGFloat(i) * colWidth + colWidth / 2
            context.draw(
                Text(dayHeaderFmt.string(from: d).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.text),
                at: CGPoint(x: cx, y: chartY - headerHeight + 14)
            )
            context.draw(
                Text(daySubFmt.string(from: d))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted),
                at: CGPoint(x: cx, y: chartY - headerHeight + 30)
            )
        }

        // --- Hour grid + Y-axis labels -------------------------------------
        for h in dayStartHour...dayEndHour {
            let y = chartY + CGFloat((Double(h) - dayStartH) / totalHours) * chartHeight
            var line = Path()
            line.move(to: CGPoint(x: chartX, y: y))
            line.addLine(to: CGPoint(x: chartX + chartWidth, y: y))
            context.stroke(line, with: .color(Theme.grid.opacity(0.45)), lineWidth: 0.5)

            context.draw(
                Text(String(format: "%02d:00", h))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.muted),
                at: CGPoint(x: chartX - 8, y: y),
                anchor: .trailing
            )
        }

        // --- Day column dividers ------------------------------------------
        for i in 0...dayCount {
            let x = chartX + CGFloat(i) * colWidth
            var line = Path()
            line.move(to: CGPoint(x: x, y: chartY))
            line.addLine(to: CGPoint(x: x, y: chartY + chartHeight))
            context.stroke(line, with: .color(Theme.grid.opacity(0.45)), lineWidth: 0.5)
        }

        // --- Lunch overlay -------------------------------------------------
        if let lunch {
            let lS = max(Double(lunch.start), dayStartH)
            let lE = min(Double(lunch.end), dayEndH)
            if lE > lS {
                let y1 = chartY + CGFloat((lS - dayStartH) / totalHours) * chartHeight
                let y2 = chartY + CGFloat((lE - dayStartH) / totalHours) * chartHeight
                let rect = CGRect(x: chartX, y: y1, width: chartWidth, height: y2 - y1)
                context.fill(Path(rect), with: .color(Theme.lunch.opacity(0.18)))
                context.draw(
                    Text("Lunch")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.lunch.opacity(0.85)),
                    at: CGPoint(x: chartX + chartWidth / 2, y: (y1 + y2) / 2)
                )
            }
        }

        // --- Events (colored by availability class) -----------------------
        let timeFmt = dateFormatter("HH:mm")

        for ev in events where !ev.isAllDay {
            guard visibleAvailabilities.contains(ev.availability) else { continue }
            guard let dayIdx = dayIndex(of: ev.start, in: days) else { continue }

            let sH = decimalHour(of: ev.start)
            let eH = decimalHour(of: ev.end)
            if eH <= dayStartH || sH >= dayEndH { continue }

            let clampedStart = max(sH, dayStartH)
            let clampedEnd = min(eH, dayEndH)

            let xLeft = chartX + CGFloat(dayIdx) * colWidth + colWidth * 0.08
            let yTop = chartY + CGFloat((clampedStart - dayStartH) / totalHours) * chartHeight
            let w = colWidth * 0.84
            let h = CGFloat((clampedEnd - clampedStart) / totalHours) * chartHeight

            let rect = CGRect(x: xLeft, y: yTop, width: w, height: h)
            drawEventBlock(rect: rect,
                           availability: ev.availability,
                           context: &context)

            if showTimes && h >= 18 {
                let label = "\(timeFmt.string(from: ev.start)) : \(timeFmt.string(from: ev.end))"
                // For Free the fill is faded — bg-color text on faded fill on
                // a dark canvas would vanish, so swap to high-contrast text.
                let labelColor: Color = (ev.availability == .free) ? Theme.text : Theme.bg
                context.draw(
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(labelColor),
                    at: CGPoint(x: xLeft + w / 2, y: yTop + h / 2)
                )
            }
        }

        // All-day events as small strips above the chart. The strips are too
        // short for hatch textures to be legible, so the differentiation falls
        // back to color + dashed outline for Free.
        var allDayCount: [Int: Int] = [:]
        for ev in events where ev.isAllDay {
            guard visibleAvailabilities.contains(ev.availability) else { continue }
            guard let dayIdx = dayIndex(of: ev.start, in: days) else { continue }
            let slot = allDayCount[dayIdx, default: 0]
            allDayCount[dayIdx] = slot + 1

            let stripH: CGFloat = 6
            let gap: CGFloat = 2
            let stripY = chartY - 4 - CGFloat(slot) * (stripH + gap) - stripH
            let xLeft = chartX + CGFloat(dayIdx) * colWidth + colWidth * 0.08
            let rect = CGRect(x: xLeft, y: stripY, width: colWidth * 0.84, height: stripH)
            let color = Theme.color(for: ev.availability)
            let path = Path(roundedRect: rect, cornerRadius: 2)
            if ev.availability == .free {
                context.fill(path, with: .color(color.opacity(0.25)))
                context.stroke(path,
                               with: .color(color),
                               style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
            } else {
                context.fill(path, with: .color(color.opacity(0.7)))
            }
        }

        // --- Legend (bottom-right) ----------------------------------------
        drawLegend(context: &context,
                   chartX: chartX,
                   chartY: chartY,
                   chartWidth: chartWidth,
                   chartHeight: chartHeight)
    }

    // MARK: - Per-availability block rendering

    /// Renders an event rect according to its availability class:
    /// solid for `.busy`, diagonal stripes for `.tentative`, faded +
    /// dashed border for `.free`, cross-hatch for `.unavailable`.
    /// The same renderer is used for the legend swatches so the legend
    /// stays a faithful key to whatever appears on the chart.
    private func drawEventBlock(
        rect: CGRect,
        availability: EventAvailability,
        context: inout GraphicsContext,
        cornerRadius: CGFloat = 4
    ) {
        let color = Theme.color(for: availability)
        let path = Path(roundedRect: rect, cornerRadius: cornerRadius)

        switch availability {
        case .busy:
            context.fill(path, with: .color(color.opacity(0.78)))
            context.stroke(path, with: .color(color), lineWidth: 0.5)

        case .tentative:
            context.fill(path, with: .color(color.opacity(0.55)))
            drawHatch(in: rect,
                      clip: path,
                      cross: false,
                      context: &context)
            context.stroke(path, with: .color(color), lineWidth: 0.5)

        case .free:
            // Faded fill + dashed border — the event exists but doesn't
            // actually block time, so we deliberately make it look "open".
            context.fill(path, with: .color(color.opacity(0.22)))
            context.stroke(path,
                           with: .color(color),
                           style: StrokeStyle(lineWidth: 1.0, dash: [4, 3]))

        case .unavailable:
            context.fill(path, with: .color(color.opacity(0.78)))
            drawHatch(in: rect,
                      clip: path,
                      cross: true,
                      context: &context)
            context.stroke(path, with: .color(color), lineWidth: 0.5)
        }
    }

    /// Draws diagonal (or cross-) hatching clipped to `clip`. Spacing is
    /// fixed in points so the pattern reads the same at chart scale and
    /// at legend-swatch scale.
    private func drawHatch(
        in rect: CGRect,
        clip: Path,
        cross: Bool,
        context: inout GraphicsContext
    ) {
        let spacing: CGFloat = 5
        let lineWidth: CGFloat = 0.9
        let hatchColor = Color.black.opacity(0.32)
        let diagLen = rect.height

        context.drawLayer { layer in
            layer.clip(to: clip)

            var path = Path()
            var x = rect.minX - diagLen
            while x < rect.maxX + diagLen {
                path.move(to: CGPoint(x: x, y: rect.maxY))
                path.addLine(to: CGPoint(x: x + diagLen, y: rect.minY))
                if cross {
                    path.move(to: CGPoint(x: x, y: rect.minY))
                    path.addLine(to: CGPoint(x: x + diagLen, y: rect.maxY))
                }
                x += spacing
            }
            layer.stroke(path, with: .color(hatchColor), lineWidth: lineWidth)
        }
    }

    /// One legend row per visible availability class. Hidden if the user
    /// turned every class off (nothing to explain).
    private func drawLegend(
        context: inout GraphicsContext,
        chartX: CGFloat,
        chartY: CGFloat,
        chartWidth: CGFloat,
        chartHeight: CGFloat
    ) {
        let rows = EventAvailability.ordered.filter { visibleAvailabilities.contains($0) }
        guard !rows.isEmpty else { return }

        let padX: CGFloat = 12
        let padY: CGFloat = 8
        let rowHeight: CGFloat = 18
        let swatchSize: CGFloat = 12
        let labelGap: CGFloat = 8
        let labelW: CGFloat = 92

        let boxW = padX * 2 + swatchSize + labelGap + labelW
        let boxH = padY * 2 + rowHeight * CGFloat(rows.count)

        let boxX = chartX + chartWidth - boxW - 8
        let boxY = chartY + chartHeight - boxH - 8

        let bg = Path(roundedRect: CGRect(x: boxX, y: boxY, width: boxW, height: boxH),
                      cornerRadius: 8)
        context.fill(bg, with: .color(Theme.surface.opacity(0.92)))
        context.stroke(bg, with: .color(Theme.grid), lineWidth: 0.5)

        for (i, avail) in rows.enumerated() {
            let rowY = boxY + padY + rowHeight * CGFloat(i) + rowHeight / 2
            let swatchRect = CGRect(
                x: boxX + padX,
                y: rowY - swatchSize / 2,
                width: swatchSize,
                height: swatchSize
            )
            drawEventBlock(rect: swatchRect,
                           availability: avail,
                           context: &context,
                           cornerRadius: 3)

            context.draw(
                Text(avail.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.text),
                at: CGPoint(x: boxX + padX + swatchSize + labelGap, y: rowY),
                anchor: .leading
            )
        }
    }

    // MARK: - Helpers

    private var isoCalendar: Calendar {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timezone
        return cal
    }

    private func dateFormatter(_ pattern: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = pattern
        f.timeZone = timezone
        return f
    }

    private func decimalHour(of date: Date) -> Double {
        let comps = isoCalendar.dateComponents([.hour, .minute, .second], from: date)
        return Double(comps.hour ?? 0)
            + Double(comps.minute ?? 0) / 60
            + Double(comps.second ?? 0) / 3600
    }

    private func dayIndex(of date: Date, in days: [Date]) -> Int? {
        let cal = isoCalendar
        return days.firstIndex { cal.isDate($0, inSameDayAs: date) }
    }
}
