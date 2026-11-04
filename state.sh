#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davinci · kernel — state
#
# Detects the current wallpaper (mpvpaper or xwww) and keeps the cached copy
# that the lock screen and SDDM read (current_wallpaper.png).
# ═══════════════════════════════════════════════════════════════════════════

# Directory of the running interactive scene, or empty.
davincix_current_scene_dir() {
    [ -f "$DAVINCIX_STATE_DIR/current_scene" ] || return 0
    pgrep -f '[x]www scene run' >/dev/null 2>&1 || return 0
    cat "$DAVINCIX_STATE_DIR/current_scene" 2>/dev/null
}

# Path of the current wallpaper, or empty.
davincix_current() {
    local src dir
    dir="$(davincix_current_scene_dir)"
    if [ -n "$dir" ]; then
        printf '%s/scene.js' "$dir"
        return 0
    fi

    if pgrep -a mpvpaper >/dev/null 2>&1; then
        src="$(pgrep -a mpvpaper | grep -o "$DAVINCIX_WALLPAPER_DIR/[^' ]*" | head -n1)"
    elif [ -x "$DAVINCIX_XWWW" ]; then
        src="$("$DAVINCIX_XWWW" query 2>/dev/null | grep -o "$DAVINCIX_WALLPAPER_DIR/[^ ]*" | head -n1)"
    fi
    printf '%s' "$src"
}

# Thumbnail name of the current wallpaper, or empty.
# Prefixed: "000_" for video, "scn_" for interactive scenes.
davincix_current_thumb_name() {
    local src base dir rel
    dir="$(davincix_current_scene_dir)"
    if [ -n "$dir" ]; then
        rel="${dir#"$DAVINCIX_WALLPAPER_DIR"/}"
        printf 'scn_%s.jpg' "$(davincix_flat_name "$rel")"
        return 0
    fi

    src="$(davincix_current)"
    [ -n "$src" ] || return 0
    base="$(basename "$src")"
    if davincix_is_video "$base"; then
        printf '000_%s' "$base"
    else
        printf '%s' "$base"
    fi
}

# Cache the current wallpaper image (used by the lock screen and SDDM).
davincix_cache_current() {
    local img="$1"
    [ -f "$img" ] && cp "$img" "$DAVINCIX_CURRENT_IMG" 2>/dev/null || true
}
