# Security

## Supported versions

Only the latest release gets fixes. Older releases are not patched; update to the newest one from the [Releases](https://github.com/EasyK0/LivePreviewSwitcher/releases) page.

## What the program touches

LivePreviewSwitcher is a local Windows tool. It:

- reads the EVE Online log files in `Documents\EVE\logs` (Local chat and combat logs) and the window titles of running EVE clients;
- writes only its own `EVE-X-Preview.json` settings file, plus `EVE-X-diag.log` in the Test variant;
- does not use the network or the registry, does not start other programs and never sends input to the game.

A report is a security issue if a build does anything outside this list, for example a network connection, writing other files, or reading files other than the EVE logs.

## Reporting a problem

Please don't post exploit details, log files or settings files in a public issue. Open an issue with only a short title such as "Security report" and ask for a private contact; the details can then be shared privately.

## What is never committed

The repository never contains built programs (`*.exe`, `dist/`), the live `EVE-X-Preview.json` settings, logs (`*.log`, `tests/results/`), local tool settings (`.claude/`) or real character names. Test fixtures use made-up names. These paths are in `.gitignore`.
