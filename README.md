# LivePreviewSwitcher

[![Tests](https://github.com/EasyK0/LivePreviewSwitcher/actions/workflows/tests.yml/badge.svg)](https://github.com/EasyK0/LivePreviewSwitcher/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/EasyK0/LivePreviewSwitcher)](https://github.com/EasyK0/LivePreviewSwitcher/releases)

An extended build of **[EVE-X-Preview](https://github.com/g0nzo83/EVE-X-Preview)**, the AutoHotkey v2 multiboxing helper for EVE Online. It shows a live thumbnail of every game client (through Windows DWM), switches clients with hotkeys, minimizes inactive clients and keeps per-profile layouts. This build adds per-character **solar system** and **live DPS** on the thumbnails, plus a set of performance and reliability fixes.

Based on EVE-X-Preview v1.0.4 by **g0nzo83**, MIT-licensed. All credit for the original program goes to its author.

## What's added

| Variant | Additions |
|---|---|
| **High** | Runs at High process priority, so thumbnails and switching stay smooth with many clients open |
| **Systems** | Each thumbnail shows the character's current solar system, read from the Local chat logs. Faster window search, title parsing only on change, immediate reaction to foreground changes |
| **Ultimate** | Live DPS per character on its thumbnail, read from the combat logs. Active-client border drawn by reshaping one window instead of showing/hiding several (≈0.6 ms instead of 5–23 ms). Thumbnail updates spread across ticks. More reliable client activation |
| **Test** | Ultimate plus a diagnostic log (`EVE-X-diag.log` in the `EVE-X Build` folder, or next to the exe) and a black-X-on-white icon. The variant for experiments and the only one that writes a log; new changes are tried here first |

### Live DPS from combat logs

The DPS counter tails every character's `Documents\EVE\logs\Gamelogs` file and averages outgoing damage over the current fight. A gap of more than 20 s starts a new fight, and the overlay hides when the fight ends. It handles the awkward parts of tailing a live log: half-written lines, hits logged out of order, several weapon groups landing in the same second, incoming damage and misses (ignored), and skipping old history at startup. Each of these is covered by a test.

## Fair play

Like the original, this tool **does not send input to the game for you**. There is no key or mouse broadcasting and no automation: one hotkey brings one client to the front, which is how EVE window-preview tools are expected to work. It reads only the game's own log files. It doesn't use the network or the registry, doesn't start other programs, and only writes its own `EVE-X-Preview.json` settings file (plus the diagnostic log in the Test variant).

## Repository layout

| Path | Contents |
|---|---|
| `upstream/` | The original EVE-X-Preview 1.0.4 script, untouched, and its [license](upstream/LICENSE) |
| `src/EVE-X-Preview.ahk` | The Ultimate script (also the base of Test) |
| `src/EVE-X-Preview-Systems.ahk`, `src/EVE-X-Preview-High.ahk` | The Systems and High scripts |
| `build/build.py` | One build script for all variants |
| `build/diag_patches.py` | The Test diagnostic layer: asserted patches applied on top of the Ultimate script |
| `tests/dps/` | DPS counter tests and replay of a recorded fight, with fixtures (made-up names) |
| `tools/` | Syntax check, load generator, process monitor, diagnostic log summary, `exticon.py` (exports the exe icons as PNG) |

The base script is the `RCDATA #1` resource of the official `EVE-X-Preview.exe` 1.0.4 release (SHA-256 `10E04F3620F7AD3EFD8A21C930E9AE97E7A15FC31D21170C74836DE48A174CB8`).

## Building

Requires Python with `pefile` and `Pillow`. The input is always the original `EVE-X-Preview.exe` 1.0.4, which is only read. One command builds High, Systems, Ultimate and Test into `dist\` and copies the changed exes into the folder with the original exe:

```
python build\build.py --target <folder with the original exe>
```

- `python build\build.py Test`: only the named variants.
- `python build\build.py --no-install`: build into `dist\` only, no copy.
- `--target` defaults to an `EVE-X` folder next to the repository folder.
- A running exe cannot be replaced: the script reports it, close the program and run it again.

Each exe is the original with its script (`RCDATA #1`) swapped for the one in `src/` and recolored icons. Test is the Ultimate script plus the patches in `build/diag_patches.py` and a black-X-on-white icon; it is the only variant that writes `EVE-X-diag.log`. A change in `src/EVE-X-Preview.ahk` therefore reaches Ultimate and Test at once. Every patch asserts that its target text appears exactly once, so a build fails loudly rather than producing a half-patched script.

## Tests

GitHub Actions runs the syntax check on every script and the DPS counter test on a Windows runner for each push and pull request (`.github/workflows/tests.yml`).

- **Syntax check:** `powershell -File tools\validate.ps1 src\EVE-X-Preview.ahk`
- **DPS counter:** `AutoHotkey64.exe tests\dps\gamesim2.ahk <empty folder>` writes simulated combat logs and checks 13 cases. Expected output: `tests/dps/fixtures/simgame5/result.txt`.
- **Replay a recorded fight:** `AutoHotkey64.exe tests\dps\replay_new.ahk tests\dps\fixtures\replay\20261010_120000_1.txt <empty folder> 3 new-delay3` takes about 70 s. Expected output: `tests/dps/fixtures/replay/replay.txt`.
- **Load test:** `powershell -File tools\loadgen.ps1 -Chars 14 -Names <client names>` writes combat logs for a running preview and removes them afterwards. Meanwhile, `tools\monitor.ps1 -ProcId <pid>` logs CPU, memory, handles and hung or error windows.
- **Switching test:** with the EVE clients of a profile running, `powershell -File tools\rapid.ps1 -Exes <exe>,<exe> -Labels <name>,<name> -Config <path to EVE-X-Preview.json> -PreviewProfile <profile>` starts each build with a copy of your settings and runs `tools\tester3.ahk`: 60 clicks on random thumbnails at 166 ms and 100 ms intervals, measuring how long until the client is in front and its border is visible.

### Switching baseline (2026-10-11)

60 switches per run; times from the thumbnail click (median / p90 / max, in ms) and missed switches (client not in front, or border not shown, within the interval).

| Build | Interval | Client in front | Missed | Border visible | Missed |
|---|---|---|---|---|---|
| Ultimate | 166 ms (6/s) | 24.9 / 31.1 / 110.1 | 0 | 28.5 / 31.6 / 144.1 | 0 |
| Ultimate | 100 ms (10/s) | 24.6 / 32.0 / 77.0 | 2 | 27.8 / 32.4 / 38.5 | 3 |
| Test v1 | 166 ms (6/s) | 27.0 / 31.7 / 38.0 | 0 | 29.9 / 34.1 / 94.7 | 0 |
| Test v1 | 100 ms (10/s) | 24.3 / 31.7 / 90.1 | 0 | 29.4 / 32.2 / 39.4 | 2 |

Both builds bring a client to the front in about 25 ms. At 10 switches per second Ultimate lost 2 of 60 (one arrived 141 ms late, one never), which is what the Test variant investigates next.

## Requirements

Windows 10/11 and AutoHotkey v2 (tested with 2.0.21).

## Contributing

New changes are tried in the Test variant first; see [CONTRIBUTING.md](CONTRIBUTING.md). Security problems: [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE), like the original. EVE Online is a trademark of CCP hf. This project is not affiliated with or endorsed by CCP.
