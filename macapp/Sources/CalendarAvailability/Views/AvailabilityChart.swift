import SwiftUI

/// The availability grid. Mirrors the spirit of the Python renderer, but
/// renders all events in a single "occupied" color (same as the lunch
/// band) so the screenshot reads as available vs. blocked time rather
/// than as a calendar legend. No per-calendar palette, no legend.
struct AvailabilityChart: View {
    let events: [AnonymizedEvent]
    let weekStart: Date
    let dayStartHour: Int
    let dayEndHour: Int
    let lunch: (start: Int, end: Int)?
    let showTimes: Bool
    let includeWeekends: Bool
    let timezone: TimeZone

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

        // --- Events (single "occupied" color) -----------------------------
        let timeFmt = dateFormatter("HH:mm")

        for ev in events where !ev.isAllDay {
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
            let rounded = Path(roundedRect: rect, cornerRadius: 4)
            context.fill(rounded, with: .color(Theme.occupied.opacity(0.78)))
            context.stroke(rounded, with: .color(Theme.occupied), lineWidth: 0.5)

            if showTimes && h >= 18 {
                let label = "\(timeFmt.string(from: ev.start)) : \(timeFmt.string(from: ev.end))"
                context.draw(
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.bg),
                    at: CGPoint(x: xLeft + w / 2, y: yTop + h / 2)
                )
            }
        }

        // All-day events as small strips above the chart, same occupied color.
        var allDayCount: [Int: Int] = [:]
        for ev in events where ev.isAllDay {
            guard let dayIdx = dayIndex(of: ev.start, in: days) else { continue }
            let slot = allDayCount[dayIdx, default: 0]
            allDayCount[dayIdx] = slot + 1

            let stripH: CGFloat = 6
            let gap: CGFloat = 2
            let stripY = chartY - 4 - CGFloat(slot) * (stripH + gap) - stripH
            let xLeft = chartX + CGFloat(dayIdx) * colWidth + colWidth * 0.08
            let rect = CGRect(x: xLeft, y: stripY, width: colWidth * 0.84, height: stripH)
            context.fill(Path(roundedRect: rect, cornerRadius: 2),
                         with: .color(Theme.occupied.opacity(0.65)))
        }

        // --- Legend (bottom-right) ----------------------------------------
        drawLegend(context: &context,
                   chartX: chartX,
                   chartY: chartY,
                   chartWidth: chartWidth,
                   chartHeight: chartHeight)
    }

    /// Single legend entry explaining that filled blocks are blocked time.
    private func drawLegend(
        context: inout GraphicsContext,
        chartX: CGFloat,
        chartY: CGFloat,
        chartWidth: CGFloat,
        chartHeight: CGFloat
    ) {
        let padX: CGFloat = 12
        let padY: CGFloat = 8
        let rowHeight: CGFloat = 18
        let swatchSize: CGFloat = 12
        let labelGap: CGFloat = 8
        let labelW: CGFloat = 110  // fits "Filled = Unavailable" at 11pt

        let boxW = padX * 2 + swatchSize + labelGap + labelW
        let boxH = padY * 2 + rowHeight

        let boxX = chartX + chartWidth - boxW - 8
        let boxY = chartY + chartHeight - boxH - 8

        let bg = Path(roundedRect: CGRect(x: boxX, y: boxY, width: boxW, height: boxH),
                      cornerRadius: 8)
        context.fill(bg, with: .color(Theme.surface.opacity(0.92)))
        context.stroke(bg, with: .color(Theme.grid), lineWidth: 0.5)

        let rowY = boxY + padY + rowHeight / 2
        let swatch = Path(
            roundedRect: CGRect(x: boxX + padX,
                                y: rowY - swatchSize / 2,
                                width: swatchSize,
                                height: swatchSize),
            cornerRadius: 3
        )
        context.fill(swatch, with: .color(Theme.occupied.opacity(0.85)))

        context.draw(
            Text("Filled = Unavailable")
                .font(.system(size: 11))
                .foregroundStyle(Theme.text),
            at: CGPoint(x: boxX + padX + swatchSize + labelGap, y: rowY),
            anchor: .leading
        )
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
