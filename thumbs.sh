#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# davinci · kernel — thumbnails
#
# Builds and maintains the picker's thumbnail cache by scanning the wallpaper
# directory RECURSIVELY:
#   - nested files are flattened into their thumb name ("a/b.jpg" → "a__b.jpg")
#   - a directory containing scene.js is an interactive scene: a single
#     "scn_<name>.jpg" thumb taken from its base image (base.jpg/jpeg/png/webp,
#     else the first image in the directory; pure-JS scenes get a placeholder)
#   - webp → jpg (ImageMagick)
#   - video poster (ffmpeg, frame at ~5s or the middle for short clips)
#   - manifest (.manifest) + source-dir marker (.source_dir)
#   - orphan cleanup when the source dir changes or files are deleted
# Runs in the background; a lock prevents duplicate runs.
# ═══════════════════════════════════════════════════════════════════════════

# May be sourced on its own (cmd_fetch); make sure the helpers are present.
if ! declare -F davinci_flat_name >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/util.sh"
fi

: "${DAVINCI_THUMB_EDGE:=1440}"
: "${DAVINCI_THUMB_QUALITY:=84}"
: "${DAVINCI_THUMB_VERSION:=2}"
THUMB_VERSION="${DAVINCI_THUMB_VERSION}:${DAVINCI_THUMB_EDGE}:${DAVINCI_THUMB_QUALITY}"
THUMB_VERSION_FILE="$DAVINCI_THUMB_DIR/.thumb_version"

# Rebuild the manifest from whatever is in the thumbnail directory.
davinci_build_manifest() {
    find "$DAVINCI_THUMB_DIR" -maxdepth 1 -type f \
        ! -name '.source_dir' ! -name '.manifest' ! -name '.thumb_version' \
        -printf "%f\n" | sort > "$DAVINCI_MANIFEST"
}

# Prepare thumbnails (async: returns immediately).
davinci_thumbs_prep() {
    mkdir -p "$DAVINCI_THUMB_DIR"

    (
        # Atomic lock: flock releases itself when this subshell exits, so a
        # prep killed mid-run can never leave a stale lock that skips future
        # runs (the old PID-file check could: a reused PID looks alive).
        exec 9>"$DAVINCI_PREP_LOCK"
        flock -n 9 || exit 0

        export THUMB_DIR="$DAVINCI_THUMB_DIR" SRC_DIR="$DAVINCI_WALLPAPER_DIR" \
               MANIFEST="$DAVINCI_MANIFEST" MAGICK_THREAD_LIMIT=1

        THUMB_SOURCE_FILE="$THUMB_DIR/.source_dir"
        if [ -f "$THUMB_SOURCE_FILE" ]; then
            read -r CACHED_SRC < "$THUMB_SOURCE_FILE"
            if [ "$CACHED_SRC" != "$SRC_DIR" ]; then
                find "$THUMB_DIR" -maxdepth 1 -type f \
                    ! -name '.source_dir' ! -name '.manifest' ! -name '.thumb_version' -delete
                echo "$SRC_DIR" > "$THUMB_SOURCE_FILE"
                > "$MANIFEST"
            fi
        else
            echo "$SRC_DIR" > "$THUMB_SOURCE_FILE"
            > "$MANIFEST"
        fi

        # Changing the thumbnail edge/quality invalidates every cached file.
        # Keep .source_dir so the source-dir migration above stays idempotent.
        if [ -f "$THUMB_VERSION_FILE" ]; then
            read -r CACHED_VERSION < "$THUMB_VERSION_FILE"
        else
            CACHED_VERSION=""
        fi
        if [ "$CACHED_VERSION" != "$THUMB_VERSION" ]; then
            find "$THUMB_DIR" -maxdepth 1 -type f \
                ! -name '.source_dir' ! -name '.manifest' -delete
            printf '%s\n' "$THUMB_VERSION" > "$THUMB_VERSION_FILE"
            > "$MANIFEST"
        fi

        # Scene directories: any directory containing scene.js.
        SCENES=$(mktemp)
        find "$SRC_DIR" -type f -name 'scene.js' -printf '%h\n' 2>/dev/null | sort > "$SCENES"

        # Remaining media files, recursively, pruning scene directories (their
        # base image belongs to the scene entry, not to the grid).
        FILES=$(mktemp)
        PRUNE_ARGS=()
        while IFS= read -r dir; do
            [ -n "$dir" ] || continue
            PRUNE_ARGS+=( -path "$dir" -prune -o )
        done < "$SCENES"
        find "$SRC_DIR" "${PRUNE_ARGS[@]}" -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
               -o -iname "*.webp" -o -iname "*.gif" \
               -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" \
               -o -iname "*.webm" \) -printf '%P\n' 2>/dev/null | sort > "$FILES"

        EXPECTED=$(mktemp)

        # ── interactive scenes ────────────────────────────────────────────
        while IFS= read -r dir; do
            [ -n "$dir" ] || continue
            rel="${dir#"$SRC_DIR"/}"
            flat="$(davinci_flat_name "$rel")"
            thumb="scn_$flat.jpg"
            echo "$thumb" >> "$EXPECTED"
            [ -f "$THUMB_DIR/$thumb" ] && continue

            base=$(find "$dir" -maxdepth 1 -type f \
                \( -iname 'base.jpg' -o -iname 'base.jpeg' -o -iname 'base.png' -o -iname 'base.webp' \) \
                2>/dev/null | sort | head -n1)
            if [ -z "$base" ]; then
                base=$(find "$dir" -maxdepth 1 -type f \
                    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
                    2>/dev/null | sort | head -n1)
            fi

            if [ -n "$base" ]; then
                magick "$base" -auto-orient -thumbnail "x${DAVINCI_THUMB_EDGE}" -strip -quality "${DAVINCI_THUMB_QUALITY}" "$THUMB_DIR/$thumb" 2>/dev/null || true
            else
                magick -size 2560x1440 xc:'#111318' -gravity center \
                    -fill '#8b93a7' -pointsize 72 -annotate 0 'scene.js' \
                    -resize "x${DAVINCI_THUMB_EDGE}" -quality "${DAVINCI_THUMB_QUALITY}" "$THUMB_DIR/$thumb" 2>/dev/null || true
            fi
        done < "$SCENES"

        # ── regular files ─────────────────────────────────────────────────
        while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            src="$SRC_DIR/$rel"
            [ -f "$src" ] || continue
            filename="${rel##*/}"
            extension="${filename##*.}"

            if [[ "${extension,,}" == "webp" ]]; then
                new_src="${src%.*}.jpg"
                new_rel="${rel%.*}.jpg"
                if magick "$src" "$new_src"; then
                    rm -f "$src"
                    src="$new_src"
                    rel="$new_rel"
                    filename="${rel##*/}"
                    extension="jpg"
                else
                    continue
                fi
            fi

            flat="$(davinci_flat_name "$rel")"
            if [[ "${extension,,}" =~ ^(mp4|mkv|mov|webm)$ ]]; then
                thumb="000_$flat"
                echo "$thumb" >> "$EXPECTED"
                [ -f "$THUMB_DIR/$thumb" ] && continue

                thumb_offset="00:00:05"
                if command -v ffprobe >/dev/null 2>&1; then
                    v_dur=$(ffprobe -v error -show_entries format=duration \
                        -of default=nw=1:nk=1 -- "$src" 2>/dev/null)
                    if [ -n "$v_dur" ]; then
                        seek_pt=$(awk -v d="$v_dur" 'BEGIN { s = (d < 6.5) ? d / 2 : 5; if (s < 0) s = 0; printf "%.0f", s }')
                        thumb_offset=$(printf "%02d:%02d:%02d" \
                            $((seek_pt / 3600)) $(((seek_pt % 3600) / 60)) $((seek_pt % 60)))
                    fi
                fi
                ffmpeg -y -ss "$thumb_offset" -i "$src" -vframes 1 \
                    -vf "scale=-2:${DAVINCI_THUMB_EDGE}" -threads 1 -f image2 -q:v 2 \
                    "$THUMB_DIR/$thumb" >/dev/null 2>&1
            else
                thumb="$flat"
                echo "$thumb" >> "$EXPECTED"
                [ -f "$THUMB_DIR/$thumb" ] && continue
                magick "$src" -auto-orient -thumbnail "x${DAVINCI_THUMB_EDGE}" -strip -quality "${DAVINCI_THUMB_QUALITY}" "$THUMB_DIR/$thumb" 2>/dev/null || true
            fi
        done < "$FILES"

        # ── orphans + manifest ────────────────────────────────────────────
        sort -o "$EXPECTED" "$EXPECTED"
        EXISTING=$(mktemp)
        find "$THUMB_DIR" -maxdepth 1 -type f \
            ! -name '.source_dir' ! -name '.manifest' ! -name '.thumb_version' -printf '%f\n' | sort > "$EXISTING"
        comm -23 "$EXISTING" "$EXPECTED" | while IFS= read -r orphan; do
            [ -n "$orphan" ] && rm -f "$THUMB_DIR/$orphan"
        done
        cp "$EXPECTED" "$MANIFEST"

        rm -f "$SCENES" "$FILES" "$EXPECTED" "$EXISTING"
    ) </dev/null >/dev/null 2>&1 &
}
