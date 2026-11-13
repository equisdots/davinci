# davinci

Wallpaper engine kernel for the [equisdots](https://github.com/equisdots)
desktop. Headless CLI that applies, thumbnails, searches and rotates
wallpapers — no shell dependency; the Quickshell picker UI lives in the
dottes shell and talks to this CLI.

Version: **0.1.0** · License: MIT

## Requirements

| Role | Tool |
|---|---|
| Apply still images | `xwww` (xwww-daemon) |
| Apply videos | `mpvpaper` |
| Thumbnails / webp / color helpers | ImageMagick (`magick`) |
| Video posters | `ffmpeg` + `ffprobe` |
| Search downloads | `curl` |
| Search scraper | `python3` (stdlib only) |
| Trash on delete | `gio` (optional; falls back to `rm`) |
| Notifications | `notify-send` (optional) |

## Install

```bash
git clone https://github.com/equisdots/davinci ~/davinci
```

The UI resolves the CLI in this order:

1. `$DAVINCI_CLI` — explicit path to `davinci.sh`.
2. Sibling `../kernel/davinci.sh` next to the UI.

So on the equisdots shell the recommended wiring is a symlink:

```bash
ln -s ~/davinci ~/.config/hypr/scripts/quickshell/davinci/kernel
```

Any other frontend only needs the CLI path.

## CLI

```bash
davinci.sh set <file|url|scene-dir> [--video] [--monitors all|A,B] \
             [--transition name] [--thumb <poster>] [--notify] [--dry-run]
davinci.sh fetch --name <n> --map <f> --dest <f> \
             [--thumb-in <f>] [--thumb-out <f>] [--monitors ...] [--transition ...]
davinci.sh current [--thumb-name]
davinci.sh thumbs
davinci.sh search <query> [--source ddg|wallhaven|pexels|pixabay]
davinci.sh search --continue <query>   # next page (keeps the cache)
davinci.sh search --clear              # stop + drop the cache
davinci.sh stop
davinci.sh rm <file|scene-dir>
davinci.sh import <paths…>
davinci.sh slideshow start|stop|status [interval]
davinci.sh keys [list | set NAME VALUE]   # provider API keys (keys.conf)
davinci.sh paths
davinci.sh --version
```


## Environment overrides

| Variable | Default | Use |
|---|---|---|
| `DAVINCI_WALLPAPER_DIR` | `$WALLPAPER_DIR` or `~/.config/hypr/wallpapers` | source directory |
| `DAVINCI_CACHE_DIR` | `~/.cache/quickshell/wallpaper_picker` | thumbs, current, search |
| `DAVINCI_STATE_DIR` | `~/.local/state/quickshell/wallpaper_picker` | persistent flags |
| `DAVINCI_RUN_DIR` | `$XDG_RUNTIME_DIR/quickshell/wallpaper_picker` | control, locks, PIDs |
| `DAVINCI_LOG_DIR` | `$XDG_RUNTIME_DIR/quickshell/logs` | logs |
| `DAVINCI_XWWW` | `~/.local/bin/xwww`, then PATH | client used by the kernel |
| `DAVINCI_XWWW_DAEMON` | `~/.local/bin/xwww-daemon`, then PATH | daemon started when missing |
| `DAVINCI_CLI` | — | consumed by the UI (CLI location) |

## Interactive scenes (xwww)

A directory inside the wallpaper dir containing `scene.js` is an interactive
scene (procedural wallpaper drawn by `xwww scene run`). `set <dir>` detects it
and starts the scene; the picker shows it as a normal entry with the `scn_`
thumbnail prefix and applies it through the same CLI.

```
wallpapers/astro-palette/
├── scene.js     the xwww scene (required)
└── base.jpg     cover image for the picker thumbnail
```

- **Thumbnail**: `thumbs/scn_<name>.jpg`, taken from `base.jpg` (or
  `base.{jpeg,png,webp}`; falls back to the first image in the directory, and
  to a placeholder for pure-JS scenes without a cover).
- **Nested files**: the scanner is recursive; a file `sub/dir/pic.jpg` becomes
  the thumb `sub__dir__pic.jpg` (`__` is the flattened separator).
- **Palette**: scenes run with `--palette equisdots`, so they follow the active
  bar palette within ~1s. The kernel keeps the cache for lock/SDDM
  (`current_wallpaper.png`) refreshed after applying.
- **State**: the active scene dir is stored in
  `$DAVINCI_STATE_DIR/current_scene`; `init.sh` re-applies it on the next
  session. Applying an image or video removes it and stops the scene.

Full reference: [docs/interactive-scenes.md](docs/interactive-scenes.md).

## Files that are contracts

- `current_wallpaper.png` — current wallpaper cache (lock screens, theme tools).
- `current_scene` (state dir) — directory of the running interactive scene.
- `ddg_search_control` — `run|pause|stop`; written by the UI.
- `search_cursors/<source>` — per-provider pagination cursor (`search --continue`).
- `search_source` — active search provider (persisted per fresh search).
- `thumbs/.manifest` + `thumbs/.source_dir` — thumbnail cache index.
- `search_map.txt` — `name|url` for search results.
- `slideshow.pid` + `slideshow_enabled` — slideshow daemon state.

## Slideshow

`slideshow start [interval]` runs a detached daemon that rotates still images
(`--transition random`) and never repeats the previous one. State lives in the
run/state dirs; resuming after a reboot needs an autostart entry in the host
(e.g. `davinci.sh slideshow start` when the enabled flag exists).

## Testing

```bash
bash davinci.sh --version
bash davinci.sh paths
bash davinci.sh current
bash davinci.sh set ~/.config/hypr/wallpapers/7.png --dry-run   # no aplica
bash davinci.sh thumbs
```

## Search notes

Search providers live in `providers/` (one script per source) and are plain
"thumb|full" emitters consumed by `search.sh`:

- `ddg.py` — DuckDuckGo (stdlib only; JSON endpoint + VQD token dance; DDG can
  change it at any time).
- `wallhaven.py` — Wallhaven public API (no key needed for SFW), native
  resolution filter and page-number pagination.
- `pexels.py` — Pexels videos API (stock clips; responds without a key today,
  sends `PEXELS_KEY` when present). thumb = preview image, full = best mp4
  >= 1920x1080.
- `pixabay.py` — Pixabay videos API (needs `PIXABAY_KEY`; free). thumb = Vimeo
  preview, full = best variant >= 1920x1080.

API keys live in `$DAVINCI_STATE_DIR/keys.conf` (sourced by `search.sh`) or the
environment: `PEXELS_KEY`, `PIXABAY_KEY`.

Video results keep an image thumbnail in the cache and the map stores the video
URL; `fetch` saves the local file with its real container extension
(`.mp4`/`.webm`), applies it with mpvpaper and the thumbnail prep builds the
`000_` poster.

Results are filtered to >= 1920x1080 and validated (`content-type` + mime)
before being kept.

## License

AGPL-3.0-or-later — see [LICENSE](LICENSE). Copyright (C) 2026 xscriptor <x@xscriptor.com>.

This repository is licensed under the GNU Affero General Public License, version 3 or any later version. If you modify the software and let users interact with it over a network, you must offer them the corresponding source.

Releases published before 2026-11-13 were distributed under the MIT License and remain available under those terms.

Third-party components, fonts, icons, images, sounds, vendored code and other assets keep their original licenses and are not covered by this license. See THIRD-PARTY.md / CREDITS.md where present.
