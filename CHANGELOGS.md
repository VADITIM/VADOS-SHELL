# Changelogs

Newest version first. The version and its number are set by the user on each push.

## Unreleased

- Transition lifecycle (`components/Lifecycle.qml`, `utils/Phases.js`): the dashboard, search and settings bodies run explicit phases (idle, preparing, entering, active, exiting, recovering). Rapid toggling always ends in a valid state, and a transition stuck longer than 3 s settles and logs instead of leaving a half-open surface.
- Shared geometry (`utils/Geometry.js`) replaces the clamps, smoothsteps and splines copied across components.
- Compositor capabilities (`Compositor.capabilities`, `Compositor.level`): features ask what the compositor can do instead of which one it is; Desktop mode needs a free canvas and window control.
- Overlay engine (`state/Overlays.qml`, `windows/OverlayWindow.qml`) replaces `Visibilities`: one registry, layer exclusion, one keyboard owner, Escape closes the topmost. Fixes the empty taskbar when switching overlays, leaving balls overwriting each other, and the taskbar not returning on one screen when an overlay opened on another. IPC target `overlay`.
- Gesture engine (`components/Gesture.qml`): the fold drag, the edge pull and the task carry run on it.
- Attention engine (`state/Attention.qml`): which notifications may pop up (critical always, do-not-disturb, fullscreen, batching, own timeouts). `attention.doNotDisturb` in `shell.json`, IPC target `attention`.
- Persistence (`services/StateFile.qml`): versioned state files in `~/.cache/vados`. Desktop mode now remembers minimized windows across a shell restart instead of stranding them off-screen.
- Reduced motion: `motion.reduced` in `shell.json`, `Motion.pace`; transitions become instant and idle bubbles and splashes stop.
- Settings: a System tab with Motion (full, reduced) and Notifications (open, quiet).
- Reopening the dashboard or search while it is leaving now rewinds it instead of starting again from an empty ball.
- Hard rules are enforced by `tools/check-rules.py`; tests in `tools/tests` (`run.py`).
- Liquid engine: one shared physics for everything liquid. Springs are characters in `Motion.liquid` (`response`, `damping`, `expansion`) played by `utils/Liquid.js` (`rise`, `ring`, `arrival`, `pull`, neck merge and separation). The burst, the settings pop, the pill pop and the taskbar drag droplet now run on it, tuned to look as before.
- Liquid material thresholds are tokens (`Appearance.liquid`).
- Activity state (`state/Activity.qml`): what the activity bar shows and where it is open, merged from notifications and the tray.
- Notification service (`services/Notifications.qml`), off by default: `notifications.enabled` in `shell.json`, `Config.setNotificationsEnabled`.
- IPC targets `activity` and `notifications`; Hyprland global shortcut `vados:activity`.

## 0.1.1

- Search: the large circle shows the user's profile picture and mutates into the found app's icon while searching.
- Config: `profile.name` and `profile.picture` (`Config.setProfile`).
