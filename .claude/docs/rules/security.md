# Security and privacy rules

Enforced by `tools/check-rules.py` where marked ✓.

- **The lock screen fails closed.** The session lock (`WlSessionLock`, ext-session-lock) lives only in `windows/LockWindow.qml` ✓ and authentication (`PamContext`) only in `services/Lock.qml` ✓. Unlocking never waits on an animation; the liquid on the lock screen is decoration that can fail without effect. A shell crash leaves the session locked (the protocol guarantees it; never use a plain overlay as a lock). Confirm driftwm supports ext-session-lock before building it.
- **The network is reached only from files listed in the README Network section** ✓, and only while the feature that needs it is on screen. No telemetry, no update checks, no font or icon downloads.
- **Secrets never touch disk.** The clipboard history skips entries offered with `x-kde-passwordManagerHint: secret` and entries from password managers; nothing secret goes into `~/.cache/vados` or `shell.json`.
- **Taking over system roles is opt-in.** The notification daemon (`notifications.enabled`) and any later role (polkit agent, clipboard owner) start off and say in the README what they replace. The clipboard history is not such a role: it only watches the clipboard, so it is on by default (user, 2026-11-11).
