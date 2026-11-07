# State rules

Enforced by `tools/check-rules.py` where marked ✓.

- **Two kinds of saved state, two places.** User choices live in `shell.json`, written only by `config/Config.qml` ✓ (each key has a setter and a README row ✓). Runtime state (history, parked windows, notification and clipboard history) lives in `~/.cache/vados/<feature>.json`, written only through a `StateFile` ✓ (`services/StateFile.qml`).
- **`shell.json` is validated against one schema** ✓ (`utils/Schema.js`, direction rule 6). Every key is in the schema, the `Config` adapter (same default) and the README, and every setter checks its value with `accept()` against the schema ✓. On load a wrong type or a value outside its choices falls back to the default and is logged once (`vados: config:`); unknown keys are logged and ignored; the file is written back only after a migration or a repair. A changed layout bumps `Schema.version` together with a step in `Schema.migrations`; a file without `version` is version 0.
- **A `StateFile` is versioned.** Bump `version` only together with a reader for the old version; a file with another version, or one that does not parse, is kept aside (`.version<N>`, `.corrupt`) and the feature starts from its defaults. A file without a version is read as plain data (pre-`StateFile` files).
- **Losing state never strands the user.** Anything that changes the desktop (parked windows) is saved as it happens and recovered on start (`Confinement.recover`), and startup never waits on a state file.
- **Writes are debounced** (`Motion.store.write`) and flushed when the owner is destroyed.
