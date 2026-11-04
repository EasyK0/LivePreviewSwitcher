# Changelog

All notable changes to LivePreviewSwitcher. Adding a new version at the top publishes a GitHub release for it.

## [Unreleased]

- Test variant (`build/legacy/build_diag7.py`): passing `mono` instead of a hue gives a black X on a white background for every icon group, tray icons included, so the experimental build is easy to tell apart. Its diagnostic log `EVE-X-diag.log` goes to the `EVE-X Build` folder next to the program when that folder exists, otherwise next to the exe.
- README: Test variant added to the variant table; its build command now makes `EVE-X-Preview-Test.exe` with the `mono` icon.
- MIT license for the whole repository (original copyright kept) and the upstream license in `upstream/LICENSE`.
- README rewritten: what each variant adds, how the DPS counter works, fair-play notes.
- `tests/dps/`: tests for the DPS counter. `gamesim2.ahk` writes fake combat logs and checks 13 cases (history skipped, single volley, incoming damage and misses ignored, half-written lines, out-of-order hits, new fight after a 20 s gap, several weapon groups in one second); `replay_new.ahk` replays a recorded fight in real time and prints the DPS shown each second. Fixtures use made-up character names.
- README: build and test sections.
- `tools/`: `validate.ps1` (AutoHotkey syntax check), `loadgen.ps1` (writes fake combat logs for many characters to load-test the log reader; names and log folder are parameters), `monitor.ps1` (CPU, memory, handles and hung/error windows of a running preview), `slowsum.ps1` (summary of SLOW entries in a diagnostic log).

## [1.3.0] - 2026-10-10

- Ultimate variant: live DPS of each character on its thumbnail, read from the EVE combat logs (`Documents\EVE\logs\Gamelogs`). It shows the average over the current fight and hides when the fight ends.
- Faster borders: the active client's border changes its window shape instead of showing and hiding windows (about 0.6 ms instead of 5-23 ms).
- Thumbnail work is spread out: a quarter of the thumbnails every 250 ms, each character still updated once per second.
- `EnsureActivation`: more reliable client activation when switching.
- `build/classes/` and `build/legacy/`: the code and build scripts for this variant.

## [1.2.0] - 2026-10-09

- Systems variant: the current solar system of each character is shown on its thumbnail, read from the EVE Local channel logs (`Documents\EVE\logs\Chatlogs`).
- Thumbnail labels: name on top, system in the middle, always white and scaled to the thumbnail width.
- Optimizations: faster EVE window search, title parsing only when a title changes, no process check or thumbnail list copy on every 50 ms tick.
- Faster switching: reacts to foreground changes at once and brings a client back if a late minimize took it away.
- `build/classes/` and `build/legacy/build8.py`: the code and build script for this variant.

## [1.1.0] - 2026-10-09

- High variant: the program sets its own process priority to High at start, so thumbnails and switching stay smooth while many EVE clients run.
- Purple tray/exe icon to tell it apart from the original.
- `build/legacy/`: first build scripts. `buildexe.py` copies the original exe, swaps in the patched script (RCDATA #1) and recolors the icons; `exticon.py` and `recolor.py` are helpers for the icons.

## [1.0.4] - 2024-07-23

- Original EVE-X-Preview 1.0.4 by g0nzo83 imported as the starting point (`upstream/` and `src/`).
