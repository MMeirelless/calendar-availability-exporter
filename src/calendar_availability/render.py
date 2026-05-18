"""Render anonymized events as a weekly grid PNG.

Calendars are mapped to generic legend labels (`Calendar 1`, `Calendar 2`, ...)
so even calendar names do not appear in the output image.
"""

from __future__ import annotations

from datetime import date, datetime, time, timedelta
from pathlib import Path

import matplotlib.patches as patches
import matplotlib.pyplot as plt

from .models import AnonymizedEvent
from .theme import PALETTE, THEME


def _to_decimal_hour(t: time | datetime) -> float:
    return t.hour + t.minute / 60 + t.second / 3600


def render(
    events: list[AnonymizedEvent],
    start_date: date,
    end_date: date,
    day_start: time,
    day_end: time,
    output_path: Path,
    lunch: tuple[time, time] | None = None,
    show_times: bool = True,
) -> None:
    """Render a dark themed weekly grid with anonymized event blocks.

    Args:
        events:      Anonymized events to render.
        start_date:  First day of the view.
        end_date:    Last day of the view (inclusive).
        day_start:   First visible hour on the Y axis.
        day_end:     Last visible hour on the Y axis.
        output_path: Destination PNG path. Parent directories are created.
        lunch:       Optional (start, end) overlay highlighting a recurring break.
        show_times:  If True, draws `HH:MM : HH:MM` labels inside each block.
    """
    days: list[date] = []
    cursor = start_date
    while cursor <= end_date:
        days.append(cursor)
        cursor += timedelta(days=1)

    day_start_h = _to_decimal_hour(day_start)
    day_end_h = _to_decimal_hour(day_end)

    fig_width = max(8, 1.5 + len(days) * 1.8)
    fig, ax = plt.subplots(figsize=(fig_width, 10), dpi=150)
    fig.patch.set_facecolor(THEME["bg"])
    ax.set_facecolor(THEME["bg"])

    ax.set_ylim(day_end_h, day_start_h)
    ax.set_xlim(-0.5, len(days) - 0.5)

    hour_ticks = list(range(int(day_start_h), int(day_end_h) + 1))
    ax.set_yticks(hour_ticks)
    ax.set_yticklabels([f"{h:02d}:00" for h in hour_ticks], color=THEME["text"])

    ax.set_xticks(range(len(days)))
    ax.set_xticklabels(
        [d.strftime("%a\n%b %d") for d in days],
        color=THEME["text"], fontsize=10,
    )
    ax.xaxis.tick_top()
    ax.tick_params(axis="both", colors=THEME["muted"], length=0)

    for h in hour_ticks:
        ax.axhline(h, color=THEME["grid"], alpha=0.4, linewidth=0.5, zorder=1)
    for x in range(len(days) + 1):
        ax.axvline(x - 0.5, color=THEME["grid"], alpha=0.4, linewidth=0.5, zorder=1)

    if lunch is not None:
        l_start, l_end = _to_decimal_hour(lunch[0]), _to_decimal_hour(lunch[1])
        ax.add_patch(patches.Rectangle(
            (-0.5, l_start), len(days), l_end - l_start,
            facecolor=THEME["lunch"], alpha=0.18, zorder=2, linewidth=0,
        ))
        ax.text(
            (len(days) - 1) / 2, (l_start + l_end) / 2, "Lunch",
            ha="center", va="center",
            color=THEME["lunch"], fontsize=14, fontweight="bold", alpha=0.85,
            zorder=3,
        )

    calendar_colors: dict[str, str] = {}

    def color_for(cal: str) -> str:
        if cal not in calendar_colors:
            calendar_colors[cal] = PALETTE[len(calendar_colors) % len(PALETTE)]
        return calendar_colors[cal]

    all_day_count: dict[int, int] = {}
    for ev in events:
        day_idx = (ev.start.date() - start_date).days
        if day_idx < 0 or day_idx >= len(days):
            for offset in range((ev.end.date() - ev.start.date()).days + 1):
                d = ev.start.date() + timedelta(days=offset)
                if start_date <= d <= end_date:
                    day_idx = (d - start_date).days
                    break
            else:
                continue

        if ev.all_day:
            slot = all_day_count.get(day_idx, 0)
            all_day_count[day_idx] = slot + 1
            strip_height = 0.18
            strip_y = day_start_h - 0.5 - slot * (strip_height + 0.05)
            ax.add_patch(patches.Rectangle(
                (day_idx - 0.42, strip_y), 0.84, strip_height,
                facecolor=color_for(ev.calendar), alpha=0.55,
                linewidth=0, zorder=4,
            ))
            continue

        ev_start_h = _to_decimal_hour(ev.start)
        ev_end_h = _to_decimal_hour(ev.end)
        if ev_end_h <= day_start_h or ev_start_h >= day_end_h:
            continue
        ev_start_h = max(ev_start_h, day_start_h)
        ev_end_h = min(ev_end_h, day_end_h)

        ax.add_patch(patches.Rectangle(
            (day_idx - 0.42, ev_start_h), 0.84, ev_end_h - ev_start_h,
            facecolor=color_for(ev.calendar), alpha=0.78,
            edgecolor=color_for(ev.calendar), linewidth=0.5, zorder=5,
        ))

        if show_times and (ev_end_h - ev_start_h) >= 0.4:
            label = f"{ev.start.strftime('%H:%M')} : {ev.end.strftime('%H:%M')}"
            ax.text(
                day_idx, (ev_start_h + ev_end_h) / 2, label,
                ha="center", va="center",
                color=THEME["bg"], fontsize=7.5, fontweight="bold",
                zorder=6,
            )

    for spine in ax.spines.values():
        spine.set_color(THEME["grid"])
        spine.set_linewidth(0.6)

    title = (
        f"Availability: {start_date.strftime('%a %b %d')} "
        f"to {end_date.strftime('%a %b %d, %Y')}"
    )
    ax.set_title(title, color=THEME["text"], fontsize=13, pad=24, loc="left")

    if calendar_colors:
        legend_handles = [
            patches.Patch(facecolor=col, alpha=0.78, label=f"Calendar {i + 1}")
            for i, (_, col) in enumerate(calendar_colors.items())
        ]
        legend = ax.legend(
            handles=legend_handles,
            loc="lower right", facecolor=THEME["surface"],
            edgecolor=THEME["grid"], labelcolor=THEME["text"],
            fontsize=8, framealpha=0.9,
        )
        legend.get_frame().set_linewidth(0.5)

    plt.tight_layout()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_path, facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
