# Changelogs

Newest version first. The version and its number are set by the user on each push.

## Unreleased

- Liquid engine: one shared physics for everything liquid. Springs are characters in `Motion.liquid` (`response`, `damping`, `expansion`) played by `utils/Liquid.js` (`rise`, `ring`, `arrival`, `pull`, neck merge and separation). The burst, the settings pop, the pill pop and the taskbar drag droplet now run on it, tuned to look as before.
- Liquid material thresholds are tokens (`Appearance.liquid`).
- Activity state (`state/Activity.qml`): what the activity bar shows and where it is open, merged from notifications and the tray.
- Notification service (`services/Notifications.qml`), off by default: `notifications.enabled` in `shell.json`, `Config.setNotificationsEnabled`.
- IPC targets `activity` and `notifications`; Hyprland global shortcut `vados:activity`.

## 0.1.1

- Search: the large circle shows the user's profile picture and mutates into the found app's icon while searching.
- Config: `profile.name` and `profile.picture` (`Config.setProfile`).
