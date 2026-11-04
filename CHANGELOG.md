# Changelog

All notable changes to the davinci kernel are documented here.
Dates use YYYY-MM-DD.

## [2026-10-02]

### Added

- **Interactive scenes**: a directory containing `scene.js` is a scene. `davinci set <dir>` starts
  it with an entry transition, `davinci current` reports `<dir>/scene.js`, `--thumb-name` reports
  the `scn_<name>.jpg` thumbnail and the picker lists it like any wallpaper.
- **Recursive wallpaper scanning**: nested media files are supported and flattened into their
  thumbnail name (`sub/dir/pic.jpg` becomes `sub__dir__pic.jpg`).
- **Scene covers**: the picker thumbnail is rendered from the scene's `base.jpg` (or the first
  image); pure-JS scenes without a cover get a placeholder.
- **Scene state**: the active scene directory is stored in `current_scene` so `init.sh` can
  restore it on the next session.
- `davinci rm` accepts scenes (the whole directory) and flattened nested paths.

### Changed

- The slideshow skips the base image of a scene directory.
- Scenes run at 15 fps (override with `DAVINCI_SCENE_FPS`), follow the active bar palette and
  resolve `random` against the full transition set, including the new reveal effects.
- The xwww client and daemon are resolved explicitly: `DAVINCI_XWWW` / `DAVINCI_XWWW_DAEMON`,
  then `~/.local/bin`, then the PATH.

### Fixed

- `davinci_ensure_xwww` launches `xwww-daemon` detached instead of blocking the caller when the
  daemon is not running.
- Scene stop also matches scene processes started through an absolute path (`[x]www scene run`).
