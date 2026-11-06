# Code quality rules

- **No comments in code. No abbreviations.** V/AS `architecture/09-code-style.md`, enforced by `.claude/settings.json` → V/AS `hooks/enforce-code-style.py`. The reason behind a number goes in `decisions.md` or `quirks.md`; the number becomes a named token. The `//@ pragma` directive in `shell.qml` is the only allowed marker.
- **LF line endings** (`.gitattributes`). Python edits write with `newline='\n'`.
- **Booleans** `is` / `has` / `should` / `can`; functions verb-first.
- **No dead code, no commented-out blocks, no premature abstractions.**
- **Tools and dependencies install under `C:\Users\vn\dependencies\<tool>`**, on PATH (user rule).
- **Commit only when asked.** Commit messages end with the `Co-Authored-By` trailer.
