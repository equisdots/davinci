#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davinci · kernel — paths
#
# Resolves every path of the wallpaper subsystem and exports it. There is no
# shell dependency: the defaults reproduce the current desktop layout
# (~/.cache/quickshell/wallpaper_picker, ...) so existing contracts keep
# working (Lock.qml, init.sh), and they can be overridden
# through the environment, which is what will allow extracting davincix as a
# standalone tool.
#
# Overrides:
#   DAVINCI_WALLPAPER_DIR    wallpaper source dir      (legacy WALLPAPER_DIR)
#   DAVINCI_CACHE_DIR        cache (thumbs, current, search)
#   DAVINCI_STATE_DIR        persistent state (flags)
#   DAVINCI_RUN_DIR          runtime (search control, locks, logs)
#   DAVINCI_LOG_DIR          logs (defaults to run/logs)
# ═══════════════════════════════════════════════════════════════════════════

# DAVINCI_* names are canonical. DAVINCIX_* aliases remain accepted for
# existing installations and scripts written before the repository rename.
DAVINCIX_WALLPAPER_DIR="${DAVINCI_WALLPAPER_DIR:-${DAVINCIX_WALLPAPER_DIR:-${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}}}"
DAVINCIX_CACHE_DIR="${DAVINCI_CACHE_DIR:-${DAVINCIX_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper_picker}}"
DAVINCIX_STATE_DIR="${DAVINCI_STATE_DIR:-${DAVINCIX_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/wallpaper_picker}}"
DAVINCIX_RUN_DIR="${DAVINCI_RUN_DIR:-${DAVINCIX_RUN_DIR:-${XDG_RUNTIME_DIR:-/tmp}/quickshell/wallpaper_picker}}"
DAVINCIX_LOG_DIR="${DAVINCI_LOG_DIR:-${DAVINCIX_LOG_DIR:-${XDG_RUNTIME_DIR:-/tmp}/quickshell/logs}}"

DAVINCI_WALLPAPER_DIR="$DAVINCIX_WALLPAPER_DIR"
DAVINCI_CACHE_DIR="$DAVINCIX_CACHE_DIR"
DAVINCI_STATE_DIR="$DAVINCIX_STATE_DIR"
DAVINCI_RUN_DIR="$DAVINCIX_RUN_DIR"
DAVINCI_LOG_DIR="$DAVINCIX_LOG_DIR"

# Derived paths (subsystem contracts).
DAVINCIX_THUMB_DIR="$DAVINCIX_CACHE_DIR/thumbs"
DAVINCIX_SEARCH_DIR="$DAVINCIX_CACHE_DIR/search_thumbs"
DAVINCIX_DOWNLOAD_DIR="$DAVINCIX_CACHE_DIR/downloads"
DAVINCIX_MAP_FILE="$DAVINCIX_CACHE_DIR/search_map.txt"
DAVINCIX_CONTROL_FILE="$DAVINCIX_RUN_DIR/ddg_search_control"
DAVINCIX_CURSOR_DIR="$DAVINCIX_RUN_DIR/search_cursors"
DAVINCIX_SOURCE_FILE="$DAVINCIX_RUN_DIR/search_source"
DAVINCIX_SLIDESHOW_PID="$DAVINCIX_RUN_DIR/slideshow.pid"
DAVINCIX_SLIDESHOW_FLAG="$DAVINCIX_STATE_DIR/slideshow_enabled"
DAVINCIX_CURRENT_IMG="$DAVINCIX_CACHE_DIR/current_wallpaper.png"
DAVINCIX_PREP_LOCK="$DAVINCIX_RUN_DIR/wallpaper_prep.lock"
DAVINCIX_MANIFEST="$DAVINCIX_THUMB_DIR/.manifest"
DAVINCIX_LOG_FILE="$DAVINCIX_LOG_DIR/xwww_debug.log"

# Binaries. The desktop session PATH may not include ~/.local/bin (where the
# installer places the scene-capable xwww build), so resolve the client and the
# daemon explicitly: env override, ~/.local/bin, then PATH.
if [ -z "${DAVINCI_XWWW:-}" ] && [ -z "${DAVINCIX_XWWW:-}" ]; then
    if [ -x "$HOME/.local/bin/xwww" ]; then
        DAVINCI_XWWW="$HOME/.local/bin/xwww"
    else
        DAVINCI_XWWW="$(command -v xwww || printf 'xwww')"
    fi
else
    DAVINCI_XWWW="${DAVINCI_XWWW:-$DAVINCIX_XWWW}"
fi
if [ -z "${DAVINCI_XWWW_DAEMON:-}" ] && [ -z "${DAVINCIX_XWWW_DAEMON:-}" ]; then
    if [ -x "$HOME/.local/bin/xwww-daemon" ]; then
        DAVINCI_XWWW_DAEMON="$HOME/.local/bin/xwww-daemon"
    else
        DAVINCI_XWWW_DAEMON="$(command -v xwww-daemon || printf 'xwww-daemon')"
    fi
else
    DAVINCI_XWWW_DAEMON="${DAVINCI_XWWW_DAEMON:-$DAVINCIX_XWWW_DAEMON}"
fi
DAVINCIX_XWWW="$DAVINCI_XWWW"
DAVINCIX_XWWW_DAEMON="$DAVINCI_XWWW_DAEMON"

davincix_ensure_dirs() {
    mkdir -p "$DAVINCIX_CACHE_DIR" "$DAVINCIX_STATE_DIR" "$DAVINCIX_RUN_DIR" \
             "$DAVINCIX_LOG_DIR" "$DAVINCIX_THUMB_DIR" "$DAVINCIX_SEARCH_DIR" \
             "$DAVINCIX_DOWNLOAD_DIR" "$DAVINCIX_CURSOR_DIR"
}

export DAVINCI_WALLPAPER_DIR DAVINCI_CACHE_DIR DAVINCI_STATE_DIR DAVINCI_RUN_DIR \
       DAVINCI_LOG_DIR DAVINCI_XWWW DAVINCI_XWWW_DAEMON \
       DAVINCIX_WALLPAPER_DIR DAVINCIX_CACHE_DIR DAVINCIX_STATE_DIR DAVINCIX_RUN_DIR \
       DAVINCIX_LOG_DIR DAVINCIX_THUMB_DIR DAVINCIX_SEARCH_DIR DAVINCIX_DOWNLOAD_DIR \
       DAVINCIX_MAP_FILE DAVINCIX_CONTROL_FILE DAVINCIX_CURSOR_DIR DAVINCIX_SOURCE_FILE \
       DAVINCIX_SLIDESHOW_PID DAVINCIX_SLIDESHOW_FLAG \
       DAVINCIX_CURRENT_IMG DAVINCIX_PREP_LOCK \
       DAVINCIX_MANIFEST DAVINCIX_LOG_FILE \
       DAVINCIX_XWWW DAVINCIX_XWWW_DAEMON
