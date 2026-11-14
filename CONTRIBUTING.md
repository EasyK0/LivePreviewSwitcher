# Contributing

Issues and pull requests are welcome. A few rules keep the stable builds stable.

## New changes go to the Test variant first

High, Systems and Ultimate are the variants people run every day. A new idea (switching, timing, log reading) is first added to the Test variant as a patch in `build/diag_patches.py`, on top of the Ultimate script. It moves to `src/EVE-X-Preview.ahk` only after it has been tried in real use and the switching test shows it is not slower. Bug fixes with a clear cause can go straight into `src/`.

Every patch in `build/diag_patches.py` asserts that its target text appears exactly once, so keep the target text short and unique.

## Before opening a pull request

- Syntax check every script you changed: `powershell -File tools\validate.ps1 <script>`.
- If you touched the DPS counter, run `tests\dps\gamesim2.ahk` and compare with `tests/dps/fixtures/simgame5/result.txt`.
- If you touched switching, run the switching test (see "Tests" in the README) and put the numbers in the pull request.
- Add a line under `## [Unreleased]` in `CHANGELOG.md`.

GitHub Actions runs the syntax check and the DPS test on every pull request.

## Keep it fair

No feature that sends keys or mouse clicks to the game (input broadcasting, automation). See "Fair play" in the README.

## Never commit

Built programs (`*.exe`, `dist/`), your `EVE-X-Preview.json`, logs (`*.log`, `tests/results/`), `.claude/` or real character names. Use made-up names in fixtures and examples. See [SECURITY.md](SECURITY.md).
