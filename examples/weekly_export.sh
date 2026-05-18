#!/usr/bin/env bash
#
# weekly_export.sh
#
# Compute the current week's Monday and Friday, then run
# calendar-availability for that window. Designed to be invoked by launchd
# every Sunday night.

set -euo pipefail

# ----- Configure these for your environment -----
PYTHON_BIN="/opt/homebrew/bin/python3"
OUTPUT_DIR="${HOME}/Documents/availability"
DAY_START="09:00"
DAY_END="20:00"
LUNCH="12:00-14:00"
# CALENDARS="Work,Personal"  # uncomment and edit to filter
# -------------------------------------------------

mkdir -p "${OUTPUT_DIR}"

# Next Monday (or today if Monday) and the Friday that follows
MONDAY=$(date -v+Mon +%Y-%m-%d)
FRIDAY=$(date -v+Mon -v+4d +%Y-%m-%d)

OUTPUT="${OUTPUT_DIR}/availability_${MONDAY}.png"

ARGS=(
    --start     "${MONDAY}"
    --end       "${FRIDAY}"
    --day-start "${DAY_START}"
    --day-end   "${DAY_END}"
    --lunch     "${LUNCH}"
    --output    "${OUTPUT}"
)

if [[ -n "${CALENDARS:-}" ]]; then
    ARGS+=(--calendars "${CALENDARS}")
fi

"${PYTHON_BIN}" -m calendar_availability "${ARGS[@]}"

echo "Generated: ${OUTPUT}"
