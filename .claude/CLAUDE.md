# VAD/OS Shell

This project is built on V/AS (VAD/OS APPLICATION SYSTEMS). Read SKILL.md in the V/AS clone (`C:\Users\vn\source\VADOS-APPLICATION-SYSTEMS`, see ~/.claude/CLAUDE.md).

A Quickshell (Qt 6 / QML) desktop shell. **driftwm first**, compatible with Hyprland and any Wayland compositor. One liquid, mutating, interactive system rather than separate widgets.

## Stack and commands

- Quickshell QML; entry `shell/shell.qml`; config `shell.json` (live-reloaded).
- Run on Linux: `qs -p ~/.config/vados/shell`.
- Preview on Windows: the PySide6 harness with mock `qs.*` modules (auto-memory `qml-preview-harness`). Services that talk to a compositor are not previewable; syntax-check them with `C:\Users\vn\dependencies\pyside6\PySide6\qmlformat.exe <file>`.
- Hard rules: `python tools/check-rules.py` (also runs as a Stop hook). Tests: `python tools/tests/run.py` (PySide6 Qt Quick tests). Both pass before every commit (`docs/rules/testing.md`).
- Releases: on command.
- Changelog: `CHANGELOGS.md` at the repo root, one section per version. On each push the user states when to bump the version and to what; then move `Unreleased` entries under the new version heading and set `shell/config/Release.qml` `version` to it. Add entries to `Unreleased` as changes land.

## Hard rules

@docs/rules/architecture.md
@docs/rules/features.md
@docs/rules/compositor.md
@docs/rules/animations.md
@docs/rules/frontend.md
@docs/rules/code-quality.md
@docs/rules/interaction.md
@docs/rules/security.md
@docs/rules/state.md
@docs/rules/performance.md
@docs/rules/testing.md
@docs/rules/reliability.md

## Keeping `.claude` current

Update these docs in the same task as the change, without being asked (V/AS `guides/claude-folder.md` §3). A Stop hook (`.claude/hooks/docs-current.py`) refuses to end a turn once when `shell/` changed after the docs did.

| Change | File |
|---|---|
| File or folder added, moved, renamed | `docs/map.md` |
| Layer, boundary, data flow | `docs/architecture.md` |
| A layer's public interface, imports or callers | `docs/interfaces.md` (owner, imports, interface, callers per layer) |
| Choice between real alternatives | `docs/decisions.md` |
| Trap, workaround, unverified assumption | `docs/quirks.md` |
| Bug or debt not fixed now | `docs/known-issues.md` |
| A surface added, built or dropped | its row in `shell/utils/Features.js`, its contract in `docs/roadmap.md` (`docs/rules/features.md`) |
| Planned work agreed or shipped | `docs/roadmap.md` (also mirrored to the Obsidian vault "VADOS Gallery" at `C:/Users/vn/Documents/Obsidian/VADOS Gallery`, folder `SHELL`, note `Shell.md`, a copy of `roadmap.md`; the feature notes it is built from sit beside it) |
| A rule the user states | `docs/rules/<domain>.md` |

`docs/direction.md` is the product direction (user, 2026-11-07): one coherent interaction engine as independently testable subsystems, built in phases (engine integrity first). Measure progress by the foundations, not the feature count.

`docs/project-notes.md` holds the early design chats (Hyprland era); it is history, not rules.
