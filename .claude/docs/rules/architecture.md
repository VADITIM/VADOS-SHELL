# Architecture rules

- **Data flows down, events flow up, nothing reaches sideways.** `config → services → components → modules → windows → shell.qml`.
- **Modules never import each other.** A feature that needs another feature's state goes through `state/` (the only sideways channel) or a signal its window maps.
- **Modules do not import `Quickshell` or the `Config` singleton.** They read `qs.config` tokens (`Appearance`, `Motion`) and `qs.services`; user settings and persistence reach them as properties, and changes leave as signals (`styleRequested`, `modeRequested`, `favoriteToggled`). Windows bridge `Config` to modules. This keeps every module previewable with mocked services.
- **Services are singletons with no UI.** A service may use another service of the same layer.
- **`keybinds/` only flips state or calls a service.** It does no work itself.
- **Windows are thin layer-shell hosts**, one per screen through `Variants` in `shell.qml`.
- **Every user setting lives in `shell.json`** through `Config.qml`'s `JsonAdapter`, with a setter function that calls `writeAdapter()`. A new key also gets a README settings row.
