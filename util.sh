#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davinci · kernel — shared helpers
#
# Logging and media-type detection used across the kernel modules.
# ═══════════════════════════════════════════════════════════════════════════

# Append a timestamped line to the subsystem log.
davinci_log() {
    echo "[$(date +'%H:%M:%S.%3N')] $*" >> "$DAVINCI_LOG_FILE"
}

# True when $1 has a video extension (query strings stripped).
davinci_is_video() {
    local f="${1%%\?*}"
    case "${f,,}" in
        *.mp4|*.mkv|*.mov|*.webm) return 0 ;;
        *) return 1 ;;
    esac
}

# True when $1 is an interactive scene directory (contains scene.js).
davinci_is_scene() {
    [ -d "$1" ] && [ -f "$1/scene.js" ]
}

# Flatten a src-dir-relative path into a thumb name: "a/b.jpg" → "a__b.jpg".
davinci_flat_name() {
    printf '%s' "${1//\//__}"
}

# Reverse of davinci_flat_name: "a__b.jpg" → "a/b.jpg".
davinci_unflat_name() {
    printf '%s' "${1//__/\/}"
}
