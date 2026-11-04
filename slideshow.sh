#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davinci · kernel — slideshow
#
# Rotates the wallpaper on an interval. It runs as a detached daemon (PID file
# + enabled flag for session restart). It only cycles STILL images (videos are
# skipped) and never repeats the current wallpaper twice in a row.
# ═══════════════════════════════════════════════════════════════════════════

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/paths.sh"
davincix_ensure_dirs

# ¿Está vivo el daemon según el PID guardado?
davincix_slideshow_alive() {
    [ -f "$DAVINCIX_SLIDESHOW_PID" ] || return 1
    kill -0 "$(cat "$DAVINCIX_SLIDESHOW_PID")" 2>/dev/null
}

# Arranca el daemon. $1 = intervalo en segundos (default 300).
davincix_slideshow_start() {
    local interval="${1:-300}"
    if davincix_slideshow_alive; then
        echo "slideshow already running (PID $(cat "$DAVINCIX_SLIDESHOW_PID"))"
        return 0
    fi

    touch "$DAVINCIX_SLIDESHOW_FLAG"

    nohup bash -c '
        DIR="$0"; interval="$1"; shift
        source "$DIR/paths.sh"
        davincix_ensure_dirs
        echo $$ > "$DAVINCIX_SLIDESHOW_PID"
        previous=""
        while true; do
            sleep "$interval"
            [ -f "$DAVINCIX_SLIDESHOW_PID" ] || break

            # Recursive: nested wallpapers participate too. The base image of a
            # scene is skipped, and the previous wallpaper never repeats.
            file=""
            for _ in 1 2 3 4 5 6 7 8; do
                candidate=$(find "$DAVINCIX_WALLPAPER_DIR" -type f \
                    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
                    -printf "%p\n" | shuf -n 1)
                [ -n "$candidate" ] || break
                [ -f "$(dirname "$candidate")/scene.js" ] && continue
                if [ -n "$previous" ] && [ "$candidate" = "$previous" ]; then continue; fi
                file="$candidate"
                break
            done
            [ -n "$file" ] || continue
            previous="$file"
            bash "$DIR/davincix.sh" set "$file" --transition random
        done
    ' "$DIR" "$interval" >/dev/null 2>&1 &

    echo "slideshow started (interval ${interval}s)"
}

# Detiene el daemon y olvida la persistencia.
davincix_slideshow_stop() {
    rm -f "$DAVINCIX_SLIDESHOW_FLAG"
    if [ -f "$DAVINCIX_SLIDESHOW_PID" ]; then
        kill "$(cat "$DAVINCIX_SLIDESHOW_PID")" 2>/dev/null || true
    fi
    rm -f "$DAVINCIX_SLIDESHOW_PID"
    echo "slideshow stopped"
}

# 0 = corriendo, 1 = parado, y además imprime el intervalo.
davincix_slideshow_status() {
    if davincix_slideshow_alive; then
        echo "running"
        return 0
    fi
    echo "stopped"
    return 1
}

case "${1:-}" in
    start) davincix_slideshow_start "${2:-300}" ;;
    stop) davincix_slideshow_stop ;;
    status) davincix_slideshow_status ;;
    *) echo "usage: slideshow.sh start|stop|status [interval-seconds]" >&2; exit 2 ;;
esac
