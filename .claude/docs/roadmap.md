# Roadmap

Ordered by the phases of `direction.md` (user, 2026-11-07): engine integrity, then one complete vertical slice, then daily-driver features, compositor support and productization. Progress is measured by the foundations, not the feature count. Shipped items move to `decisions.md`. Mirrored to the Obsidian vault "VADOS SHELL", note `Shell.md`.

## Phase 1: engine integrity (now)

Exit: transitions can be created, interrupted, reversed and chained without inconsistent visual or logical states.

- Shipped: liquid engine, motion tokens and reduced motion, overlay engine, gesture engine, transition lifecycle with recovery, shared geometry, compositor capabilities, persistence, enforced rules and tests; overlays joined with the lifecycles, leave geometry that follows screen changes, a measured script frame budget; subsystem interfaces and ownership (`interfaces.md`) with enforced import direction (2026-11-07).
- Left: verify on hardware and budget the render cost there (`known-issues.md`). Phase 2 can start.

## Phase 2: vertical slice (taskbar and search)

Exit: search works as a finished daily-use feature, not an animation demonstration.

- Taskbar-to-search morph and return, keyboard and pointer, rapid input, error and recovery behaviour; then **verify on driftwm** (item 3 below).

## Phase 3 onwards: daily driver, compositors, productization

The numbered list below is the daily-driver backlog (phase 3: settings, notifications, controls, clipboard, tray, multi-monitor). Phase 4 completes the driftwm adapter and other backends on `Compositor.capabilities` (the contract and the README "Compositor support" table shipped 2026-11-07; left: test each backend for real, focus tracking on generic Wayland); phase 5 is installation, config validation and migration, logging and diagnostics.

## Next

0. **Engines in place (2026-11-07)**: overlay, gesture, attention, persistence, reduced motion. New features build on them: the lock screen is an `OverlayWindow`-free `LockWindow` (`rules/security.md`), clipboard is an overlay with a `StateFile`, notifications draw `Attention.peek` with `Gesture` swipes.
1. **Activity bar** (agreed 2026-11-05): a dynamic island that lives inside the taskbar, opened from the compact idle column. It shows what is happening now: the playing music, Discord calls, notifications, the system tray, and more over time. VAD/OS BUBBLE (`C:\Users\vn\source\VADOS-BUBBLE`) already has a first version of this; port it into the shell, improve it, and bring it in line with V/AS. Foundations shipped 2026-11-06: `state/Activity.qml` (what is current and where the bar is open) and `services/Notifications.qml` (off by default); still to build: the bar itself, a media (Mpris) source and calls, then turn `notifications.enabled` on by default.
2. **Settings on the burst**: settings is the last overlay not growing out of the taskbar column with the dashboard's `Burst` (left alone on 2026-11-05 at the user's request).
3. **Verify on driftwm.** Run the shell in a real session and check every assumption in `quirks.md` § Unverified driftwm assumptions: camera centre, Y-up, fullscreen/pinned shapes, negative `move`.
5. **Desktop mode, Windows parity:**
   - Aero-snap by dragging a window to a screen edge or corner, with a liquid preview of the target region.
   - Super+Up/Down cycle (restore → maximize → minimize).
   - Remember each window's restore geometry across maximize.
   - Show desktop (Super+D parks everything, again restores).
   - Alt+Tab switcher as a liquid pill strip.
6. **Canvas mode tooling:**
   - Minimap pill of the infinite canvas (windows as droplets, viewport as a lens).
   - Bookmarks exported to the taskbar as liquid tabs.
   - Recenter and zoom-to-fit controls in the activity bar.
7. **Mode transition animation.** Switching Canvas ↔ Desktop gets a named V/AS motion: windows fly to their parked or restored spots; the camera eases home.

## Later

- **User profiles** (agreed 2026-11-06): several profiles with name and picture, chosen in settings. Today a single `profile` in `shell.json` feeds the search circle.
- **Notifications** (`modules/notifications`): alert band pulled from the top edge, liquid stack (V/AS `components/15-alert-band.md`).
- **More abilities**: the taskbar carry as a drag ability, a right click ability, `Jolt` on more surfaces.
- **Dashboard wave**: the shelved pour-out wave and idle ripple (`shelf/dashboard-wave/`) could return as an option.
- **Dashboard follow-ups**: real icons, a widget in the `[EMPTY]` slot, quick settings with drag-only sliders (V/AS `components/13-dashboard.md`), weather unit and day names.
- **Widgets** on the canvas as driftwm `widget = true` windows that follow the camera.
- **Media** with a wave level, inside the activity bar.
- **Search**: calculator and file results, actions ("shutdown", "settings"), drag a result tile onto the taskbar to pin it.
- **Unified icon set** stored in V/AS, replacing the theme lookup.
- **Per-compositor blur** for driftwm through layer rules once its layer-rule syntax is confirmed.
- **Blip** upload/download inside the notifications panel when Blip is installed; drop a file on a device to upload it.
- **VAD/OS family integration**: detect installed VAD/OS apps and surface them inside the shell.
- **Screenshot interface** in the style of Lightshot: instant region select, fast and smooth.
- **Clipboard manager** on SUPER + V, as on Windows.
