#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davinci · kernel — paths
#
# Resolves every path of the wallpaper subsystem and exports it. There is no
# shell dependency: the defaults reproduce the current desktop layout
# (~/.cache/quickshell/wallpaper_picker, ...) so existing contracts keep
# working (Lock.qml, init.sh), and they can be overridden through the
# environment.
#
# Overrides:
#   DAVINCI_WALLPAPER_DIR    wallpaper source dir      (legacy WALLPAPER_DIR)
#   DAVINCI_CACHE_DIR        cache (thumbs, current, search)
#   DAVINCI_STATE_DIR        persistent state (flags)
#   DAVINCI_RUN_DIR          runtime (search control, locks, logs)
#   DAVINCI_LOG_DIR          logs (defaults to run/logs)
# ═══════════════════════════════════════════════════════════════════════════

DAVINCI_WALLPAPER_DIR="${DAVINCI_WALLPAPER_DIR:-${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}}"
DAVINCI_CACHE_DIR="${DAVINCI_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpaper_picker}"
DAVINCI_STATE_DIR="${DAVINCI_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/wallpaper_picker}"
DAVINCI_RUN_DIR="${DAVINCI_RUN_DIR:-${XDG_RUNTIME_DIR:-/tmp}/quickshell/wallpaper_picker}"
DAVINCI_LOG_DIR="${DAVINCI_LOG_DIR:-${XDG_RUNTIME_DIR:-/tmp}/quickshell/logs}"

# Derived paths (subsystem contracts).
DAVINCI_THUMB_DIR="$DAVINCI_CACHE_DIR/thumbs"
DAVINCI_SEARCH_DIR="$DAVINCI_CACHE_DIR/search_thumbs"
DAVINCI_DOWNLOAD_DIR="$DAVINCI_CACHE_DIR/downloads"
DAVINCI_MAP_FILE="$DAVINCI_CACHE_DIR/search_map.txt"
DAVINCI_CONTROL_FILE="$DAVINCI_RUN_DIR/ddg_search_control"
DAVINCI_CURSOR_DIR="$DAVINCI_RUN_DIR/search_cursors"
DAVINCI_SOURCE_FILE="$DAVINCI_RUN_DIR/search_source"
DAVINCI_SLIDESHOW_PID="$DAVINCI_RUN_DIR/slideshow.pid"
DAVINCI_SLIDESHOW_FLAG="$DAVINCI_STATE_DIR/slideshow_enabled"
DAVINCI_CURRENT_IMG="$DAVINCI_CACHE_DIR/current_wallpaper.png"
DAVINCI_PREP_LOCK="$DAVINCI_RUN_DIR/wallpaper_prep.lock"
DAVINCI_MANIFEST="$DAVINCI_THUMB_DIR/.manifest"
DAVINCI_LOG_FILE="$DAVINCI_LOG_DIR/xwww_debug.log"

# Binaries. The desktop session PATH may not include ~/.local/bin (where the
# installer places the scene-capable xwww build), so resolve the client and the
# daemon explicitly: env override, ~/.local/bin, then PATH.
if [ -z "${DAVINCI_XWWW:-}" ]; then
    if [ -x "$HOME/.local/bin/xwww" ]; then
        DAVINCI_XWWW="$HOME/.local/bin/xwww"
    else
        DAVINCI_XWWW="$(command -v xwww || printf 'xwww')"
    fi
fi
if [ -z "${DAVINCI_XWWW_DAEMON:-}" ]; then
    if [ -x "$HOME/.local/bin/xwww-daemon" ]; then
        DAVINCI_XWWW_DAEMON="$HOME/.local/bin/xwww-daemon"
    else
        DAVINCI_XWWW_DAEMON="$(command -v xwww-daemon || printf 'xwww-daemon')"
    fi
fi

davinci_ensure_dirs() {
    mkdir -p "$DAVINCI_CACHE_DIR" "$DAVINCI_STATE_DIR" "$DAVINCI_RUN_DIR" \
             "$DAVINCI_LOG_DIR" "$DAVINCI_THUMB_DIR" "$DAVINCI_SEARCH_DIR" \
             "$DAVINCI_DOWNLOAD_DIR" "$DAVINCI_CURSOR_DIR"
}

export DAVINCI_WALLPAPER_DIR DAVINCI_CACHE_DIR DAVINCI_STATE_DIR DAVINCI_RUN_DIR \
       DAVINCI_LOG_DIR DAVINCI_THUMB_DIR DAVINCI_SEARCH_DIR DAVINCI_DOWNLOAD_DIR \
       DAVINCI_MAP_FILE DAVINCI_CONTROL_FILE DAVINCI_CURSOR_DIR DAVINCI_SOURCE_FILE \
       DAVINCI_SLIDESHOW_PID DAVINCI_SLIDESHOW_FLAG \
       DAVINCI_CURRENT_IMG DAVINCI_PREP_LOCK \
       DAVINCI_MANIFEST DAVINCI_LOG_FILE \
       DAVINCI_XWWW DAVINCI_XWWW_DAEMON
