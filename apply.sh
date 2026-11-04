#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davinci · kernel — apply
#
# Applies wallpapers: xwww for still images (with transitions) and mpvpaper
# for video. Starts xwww-daemon when missing and resolves "random"
# transitions. No UI, no search, no download logic here.
# ═══════════════════════════════════════════════════════════════════════════

# Valid xwww transitions (davincix_resolve_transition picks one for "random").
DAVINCIX_TRANSITIONS=(simple fade left right top bottom wipe grow center outer wave glitch decrypt dissolve clock zoom pixelate ripple blinds spiral static parallax parallax-left parallax-right parallax-invert melt shatter)

# Start xwww-daemon if it is not alive.
davincix_ensure_xwww() {
    pgrep -x xwww-daemon >/dev/null 2>&1 && return 0

    # xwww-daemon runs in the foreground, so detach it. Launching it directly
    # would block this function (and the caller) for as long as it lives.
    setsid nohup "$DAVINCIX_XWWW_DAEMON" >/dev/null 2>&1 < /dev/null &
    sleep 0.5

    if ! pgrep -x xwww-daemon >/dev/null 2>&1; then
        notify-send "Wallpaper Error" "Failed to start xwww-daemon" -u critical -t 5000
        return 1
    fi
}

# Resolve a transition: empty/"random" → pick one; anything else passes through.
davincix_resolve_transition() {
    local t="${1:-}"
    if [ -z "$t" ] || [ "$t" = "random" ]; then
        echo "${DAVINCIX_TRANSITIONS[$((RANDOM % ${#DAVINCIX_TRANSITIONS[@]}))]}"
    else
        echo "$t"
    fi
}

# Stop the interactive scene runner, if any. The bracket keeps the pattern from
# matching the caller's own command line while still matching both "xwww scene
# run" and the absolute-path invocation ("/home/.../xwww scene run").
davincix_scene_stop() {
    pkill -f '[x]www scene run' 2>/dev/null || true
    rm -f "$DAVINCIX_STATE_DIR/current_scene"
}

# Apply an interactive scene directory (must contain scene.js).
# $1=dir $2=monitors $3=transition (empty/"random" picks one, like images)
davincix_set_scene() {
    local dir="$1" monitors="${2:-all}" transition="${3:-}"
    davincix_is_scene "$dir" || return 1

    davincix_ensure_xwww || return 1
    davincix_scene_stop
    pkill mpvpaper 2>/dev/null || true

    local t
    t="$(davincix_resolve_transition "$transition")"

    davincix_log "APPLY SCENE: $dir → $monitors (${t})"

    local args=(scene run "$dir/scene.js" --palette equisdots --fps "${DAVINCI_SCENE_FPS:-${DAVINCIX_SCENE_FPS:-15}}" --timeout-ms 2000
                --transition-type "$t" --transition-duration 1 --transition-fps 144
                --transition-pos 0.5,0.5)
    # 'simple' is step-driven (its default step in scene run is instant).
    [ "$t" = "simple" ] && args+=(--transition-step 2)
    [ "$monitors" != "all" ] && args+=(--outputs "$monitors")
    setsid nohup "$DAVINCIX_XWWW" "${args[@]}" >> "$DAVINCIX_LOG_FILE" 2>&1 &

    mkdir -p "$DAVINCIX_STATE_DIR"
    printf '%s\n' "$dir" > "$DAVINCIX_STATE_DIR/current_scene"

    # Refresh the lock/SDDM cache with the first rendered frame (best effort;
    # never blocks the caller).
    (
        sleep 2
        local mon
        mon="$("$DAVINCIX_XWWW" query 2>/dev/null | sed -n 's/^: \([^:]*\):.*/\1/p' | head -n1)"
        [ -n "$mon" ] && "$DAVINCIX_XWWW" screenshot "$DAVINCIX_CURRENT_IMG" -m "$mon" >/dev/null 2>&1
    ) </dev/null >/dev/null 2>&1 &
}

# Apply a still image. $1=file $2=monitors ("all" or "A,B") $3=transition
davincix_set_image() {
    local file="$1" monitors="${2:-all}" transition="$3"
    local t
    t="$(davincix_resolve_transition "$transition")"

    davincix_ensure_xwww || return 1
    davincix_scene_stop
    pkill mpvpaper 2>/dev/null || true
    davincix_log "APPLY IMAGE: $file → $monitors (${t})"

    if [ "$monitors" = "all" ]; then
        "$DAVINCIX_XWWW" img "$file" --transition-type "$t" --transition-pos 0.5,0.5 \
            --transition-fps 144 --transition-duration 1 >> "$DAVINCIX_LOG_FILE" 2>&1 &
    else
        "$DAVINCIX_XWWW" img -o "$monitors" "$file" --transition-type "$t" --transition-pos 0.5,0.5 \
            --transition-fps 144 --transition-duration 1 >> "$DAVINCIX_LOG_FILE" 2>&1 &
    fi
}

# Apply a video. $1=file $2=monitors
davincix_set_video() {
    local file="$1" monitors="${2:-all}"
    local opts='loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample'
    davincix_log "APPLY VIDEO: $file → $monitors"

    davincix_scene_stop

    if [ "$monitors" = "all" ]; then
        mpvpaper -o "$opts" '*' "$file" >> "$DAVINCIX_LOG_FILE" 2>&1 &
    else
        local mon
        IFS=',' read -ra MON_ARR <<< "$monitors"
        for mon in "${MON_ARR[@]}"; do
            mpvpaper -o "$opts" "$mon" "$file" >> "$DAVINCIX_LOG_FILE" 2>&1 &
        done
    fi
}
