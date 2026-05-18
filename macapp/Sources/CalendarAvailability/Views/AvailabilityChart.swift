import SwiftUI

/// The availability grid. Mirrors `src/calendar_availability/render.py`
/// so the in-app preview matches the exported PNG.
///
/// Drawn entirely in a `Canvas` so it renders crisply at any size and
/// can be rasterized by `ImageRenderer` for export with no layout drift.
struct AvailabilityChart: View {
    let events: [AnonymizedEvent]
    let weekStart: Date
    let dayStartHour: Int
    let dayEndHour: Int
    let lunch: (start: Int, end: Int)?
    let showTimes: Bool
    /// Stable mapping from calendar title to palette index, so colors
    /// don't shuffle when the visible event set changes between weeks.
    let paletteIndex: (String) -> Int

    private static let dayHeader: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let daySub: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let titleFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    private static let titleEndFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d, yyyy"
        return f
    }()

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            draw(context: &context, size: size)
        }
        .background(Theme.bg)
    }

    // MARK: - Drawing

    private func draw(context: inout GraphicsContext, size: CGSize) {
        let cal = Self.isoCalendar
        let days: [Date] = (0..<7).compactMap {
            cal.date(byAdding: .day, value: $0, to: weekStart)
        }
        guard days.count == 7 else { return }

        let dayStartH = Double(dayStartHour)
        let dayEndH = Double(dayEndHour)
        let totalHours = max(dayEndH - dayStartH, 1)

        // --- Layout --------------------------------------------------------
        let padding: CGFloat = 24
        let titleHeight: CGFloat = 28
        let headerHeight: CGFloat = 44
        let leftAxis: CGFloat = 56
        let bottomPad: CGFloat = 16

        let chartX = padding + leftAxis
        let chartY = padding + titleHeight + headerHeight
        let chartWidth = size.width - chartX - padding
        let chartHeight = size.height - chartY - bottomPad
        let colWidth = chartWidth / 7

        guard chartWidth > 50, chartHeight > 50 else { return }

        // --- Title ---------------------------------------------------------
        let title = "Availability: \(Self.titleFmt.string(from: days.first!)) to \(Self.titleEndFmt.string(from: days.last!))"
        context.draw(
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text),
            at: CGPoint(x: padding, y: padding + titleHeight / 2),
            anchor: .leading
        )

        // --- Day headers ---------------------------------------------------
        for (i, d) in days.enumerated() {
            let cx = chartX + CGFloat(i) * colWidth + colWidth / 2
            context.draw(
                Text(Self.dayHeader.string(from: d).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.text),
                at: CGPoint(x: cx, y: chartY - headerHeight + 14)
            )
            context.draw(
                Text(Self.daySub.string(from: d))
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
        for i in 0...7 {
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

        // --- Events --------------------------------------------------------
        var calendarsSeen: [String: Color] = [:]

        // First pass: timed events.
        for ev in events where !ev.isAllDay {
            guard let dayIdx = dayIndex(of: ev.start, in: days) else { continue }

            let sH = decimalHour(of: ev.start)
            let eH = decimalHour(of: ev.end)
            if eH <= dayStartH || sH >= dayEndH { continue }

            let clampedStart = max(sH, dayStartH)
            let clampedEnd = min(eH, dayEndH)

            let color = Theme.palette[paletteIndex(ev.calendar) % Theme.palette.count]
            calendarsSeen[ev.calendar] = color

            let xLeft = chartX + CGFloat(dayIdx) * colWidth + colWidth * 0.08
            let yTop = chartY + CGFloat((clampedStart - dayStartH) / totalHours) * chartHeight
            let w = colWidth * 0.84
            let h = CGFloat((clampedEnd - clampedStart) / totalHours) * chartHeight

            let rect = CGRect(x: xLeft, y: yTop, width: w, height: h)
            let rounded = Path(roundedRect: rect, cornerRadius: 4)
            context.fill(rounded, with: .color(color.opacity(0.78)))
            context.stroke(rounded, with: .color(color), lineWidth: 0.5)

            if showTimes && h >= 18 {
                let label = "\(Self.timeFmt.string(from: ev.start)) : \(Self.timeFmt.string(from: ev.end))"
                context.draw(
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.bg),
                    at: CGPoint(x: xLeft + w / 2, y: yTop + h / 2)
                )
            }
        }

        // Second pass: all-day events as strips above the chart.
        var allDayCount: [Int: Int] = [:]
        for ev in events where ev.isAllDay {
            guard let dayIdx = dayIndex(of: ev.start, in: days) else { continue }
            let slot = allDayCount[dayIdx, default: 0]
            allDayCount[dayIdx] = slot + 1

            let color = Theme.palette[paletteIndex(ev.calendar) % Theme.palette.count]
            calendarsSeen[ev.calendar] = color

            let stripH: CGFloat = 6
            let gap: CGFloat = 2
            let stripY = chartY - 4 - CGFloat(slot) * (stripH + gap) - stripH
            let xLeft = chartX + CGFloat(dayIdx) * colWidth + colWidth * 0.08
            let rect = CGRect(x: xLeft, y: stripY, width: colWidth * 0.84, height: stripH)
            context.fill(Path(roundedRect: rect, cornerRadius: 2),
                         with: .color(color.opacity(0.55)))
        }

        // --- Legend (bottom-right) ----------------------------------------
        if !calendarsSeen.isEmpty {
            drawLegend(context: &context,
                       calendars: calendarsSeen,
                       chartX: chartX,
                       chartY: chartY,
                       chartWidth: chartWidth,
                       chartHeight: chartHeight)
        }
    }

    private func drawLegend(
        context: inout GraphicsContext,
        calendars: [String: Color],
        chartX: CGFloat,
        chartY: CGFloat,
        chartWidth: CGFloat,
        chartHeight: CGFloat
    ) {
        // Order matches paletteIndex so labels stay stable across weeks.
        let ordered = calendars.sorted { paletteIndex($0.key) < paletteIndex($1.key) }
        let rowHeight: CGFloat = 16
        let padX: CGFloat = 10
        let padY: CGFloat = 8
        let swatchSize: CGFloat = 10
        let labelGap: CGFloat = 6
        let maxLabelWidth: CGFloat = 70

        let boxW: CGFloat = padX * 2 + swatchSize + labelGap + maxLabelWidth
        let boxH: CGFloat = padY * 2 + CGFloat(ordered.count) * rowHeight

        let boxX = chartX + chartWidth - boxW - 8
        let boxY = chartY + chartHeight - boxH - 8

        let bg = Path(roundedRect: CGRect(x: boxX, y: boxY, width: boxW, height: boxH),
                      cornerRadius: 8)
        context.fill(bg, with: .color(Theme.surface.opacity(0.9)))
        context.stroke(bg, with: .color(Theme.grid), lineWidth: 0.5)

        for (i, (_, color)) in ordered.enumerated() {
            let rowY = boxY + padY + CGFloat(i) * rowHeight + rowHeight / 2

            let swatch = Path(
                roundedRect: CGRect(x: boxX + padX,
                                    y: rowY - swatchSize / 2,
                                    width: swatchSize,
                                    height: swatchSize),
                cornerRadius: 2
            )
            context.fill(swatch, with: .color(color.opacity(0.85)))

            context.draw(
                Text("Calendar \(i + 1)")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.text),
                at: CGPoint(x: boxX + padX + swatchSize + labelGap, y: rowY),
                anchor: .leading
            )
        }
    }

    // MARK: - Helpers

    private func decimalHour(of date: Date) -> Double {
        let comps = Self.isoCalendar.dateComponents([.hour, .minute, .second], from: date)
        return Double(comps.hour ?? 0)
            + Double(comps.minute ?? 0) / 60
            + Double(comps.second ?? 0) / 3600
    }

    private func dayIndex(of date: Date, in days: [Date]) -> Int? {
        let cal = Self.isoCalendar
        let target = cal.startOfDay(for: date)
        return days.firstIndex { cal.isDate($0, inSameDayAs: target) }
    }

    private static var isoCalendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        return cal
    }()
}
