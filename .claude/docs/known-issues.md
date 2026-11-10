# Known issues

- **`tst_features.qml` has never run (2026-11-10).** It was written on a machine without PySide6 and the user chose not to install it there. Checked instead: the registry evaluated with Node (`overlayKinds()` gives search, dashboard and settings on layer 1), and every `[features]` check seen failing on a deliberately broken registry. Unverified: the test file itself, the `Overlays.kinds` binding inside QML (`tst_overlays` depends on it), and both measured ready budgets. Run `python tools/tests/run.py` on a machine with PySide6 before committing (`rules/testing.md`).
- **Ready budgets cover two engines only (2026-11-10).** `tst_features` measures `Burst` and `Mutate`; the activity pill's `Reshape` (expanded view) and the Wi-Fi `Extension` are not measured against `Motion.budget.ready`, and the measurement is offscreen script time plus the animation clock, not a real compositor frame.
- **Planned surfaces have a row and a contract but no code** (`alerts`, `clipboard`, `notifications`, `lock`, `widgets`, `canvas`); two points in `roadmap.md` § Still open wait for the user (the app manager's move action, keyboard focus for the V/AI widget).
- **Catalogues are review-only.** Nothing checks that a `Lock.js` module, a settings tab or an activity key has its file; the `[features]` check stops at the surface.

- **The capability contract is unverified on real compositors** (2026-11-07). `Platform.js` claims what the code paths implement; none was run against driftwm, Hyprland or a plain Wayland compositor here. Unchecked: whether `GlobalShortcut` warns or stays silent where the Hyprland protocol is missing, and whether driftwm offers that protocol.
- **Generic Wayland has no focus tracking**: `Compositor.focusedScreen` stays on the first screen, so shortcuts, IPC overlays and notification peeks open there on multi-monitor setups. `ToplevelManager.activeToplevel.screens` could supply it; not built.
- **Search and dashboard read `Appearance.taskbar.margin`** (another feature's group) for their root column. It is shared geometry with the taskbar they grow out of; the checker covers only components, not module-to-feature token reads.
- **Components still hold literal pixel sizes** (`ColorWheel` spacing 10, margins 12 and 6, borders) that predate the token rule; the feature-agnostic rule only checks token groups.

- **`Config`'s load repair has not run in Quickshell** (2026-11-07). Only `utils/Schema.js` is tested; the order of `JsonAdapter`'s own read and `FileView.loaded`, whether `JsonAdapter` keeps unknown keys when it writes, and whether its own writes come back through `fileChanged` are unverified. The repair runs a tick after `loaded` to be safe from the first; the tests have no `JsonAdapter` fake.
- **A `shell.json` from a newer shell is downgraded by the first setter call**: load never writes it, but a setter writes `version` and only the keys this shell knows.
- **`taskbar.enabled` has no setter**; it is only set by hand in `shell.json`.
- **`rendering.quality` has no reader yet**; the rendering workstream builds the lite path.

- **The dashboard's leaving ball in the taskbar is unverified.** The hand-off assumes the dashboard and taskbar windows share the screen's top edge and full height, so their y coordinates match; with a taskbar margin or exclusive zone on top the ball would jump at the hand-off.
- **Taskbar toplevels are matched to driftwm windows by `app_id` + title.**
  - Two windows with the same app and title can resolve to the wrong window.
  - Upgrade path: match by pid once Quickshell exposes pid on toplevels.
- **Confinement clamps windows the user drags partly off-screen.** The clamp fires after the 140 ms settle, so a slow drag past the edge can fight it.
- **The generic backend has no geometry.** There the taskbar hides only for fullscreen or maximized windows.
- **Phase 1 of `direction.md` is done in the preview, not on hardware:**
  - Render cost (blur, `Shape` tessellation) is not budgeted; `tst_budget` measures script work only. Profile on real hardware (QML profiler, `QSG_RENDER_TIMING=1`).
  - `keepScreens` on a real monitor unplug, and the phase reports from `OverlayWindow`, have not run in Quickshell.
  - The dashboard and settings are not in `tst_budget`; the search burst is the heaviest, so they are assumed to fit.
- **Untested on real hardware:**
  - driftwm IPC
  - Hyprland `GlobalShortcut`
  - layerrule blur (`vados-search`, `vados-settings`)
  - the settings origin and taskbar parts on a right-edge taskbar and on scaled outputs
  - the same-frame handoff between the taskbar window (cut to opacity 0) and the settings overlay on a real compositor
  - `DesktopEntry.execute()`
  - `JsonAdapter` persistence of `var` values
  - the dashboard's hardware probe, weather fetch and `vados-dashboard` blur rule
- **Dashboard gaps**: no reading for Intel iGPUs and no choice between GPUs (the first card wins); disks on one filesystem (btrfs subvolumes) collapse into one row; weather is Celsius only, with no day names.
- **Wi-Fi extension**: clicking a network runs `nmcli device wifi connect`, which only works for open networks and saved profiles; there is no password entry yet. The fused style has no `EdgeFuse` on the extension body. Not yet run on the Linux shell.
- **System tray items have no place in the taskbar** since the `...` pill was removed (2026-11-05). `services/Tray.qml` feeds `Activity.entries` for the activity bar, which is planned to host them.
- **Notifications have no surface yet.** `services/Notifications.qml` and `state/Activity.qml` exist, but nothing draws them until the activity bar and the alert band land; `notifications.enabled` stays off until then (`decisions.md`).
- **Not yet on the gesture engine**: nothing left in the shell; new swipes (notifications, clipboard rows) must use `Gesture`.
- **Rendering cost is unmeasured on a GPU (2026-11-07).** `tst_rendering` proves which passes run (lite has no blur, an unshown layer runs none), not what they cost. Still to profile on real hardware: a full against a lite liquid, the search favourites mask (two full-screen layers re-rendered every frame of the burst), and the extension's liquid stacked over the taskbar's while grown. Lite has no settings toggle yet (`rendering.quality` in `shell.json` only).
- **The shelved `shelf/dashboard-wave/Dashboard.qml` would not load as is**: `LiquidLayer` now requires `isShown`.
- **Supervision is untested in Quickshell (2026-11-07):** tested against a fake `Process` only. Unverified: that a command that cannot start flips `running` back to false (the supervisor counts that as `failed to start`), the `ping` exit when the network is down, `nmcli monitor` and `udevadm monitor` exits, and the `diagnostics` IPC returning multi-line text through `qs ipc call`. Hyprland's `hyprctl` queries and `Hardware`'s probe are not supervised (a poll repeats them) and fail silently.
- **Untested on real hardware (engines, 2026-11-07):** `OverlayWindow` keyboard hand-over between overlays, `StateFile` writes through `FileView.setText` and its `mkdir`, `Confinement.recover` on a live driftwm, `Notification.expireTimeout` being in seconds.
- **Untested on real hardware (notifications, 2026-11-06):** the `NotificationServer` registering, actions and images, and replacing a running mako or dunst.
- **Search has no rising bubbles**: its body spans the full screen height, so `Rising` (top and bottom surfaces to the screen edges) has no room.
- **The dashboard's top step is not a hit area**: the body `MouseArea` covers only the rectangle, so a click on the top step closes the dashboard. The bottom step (disk notch) has its own `MouseArea`.
- **The expanded activity pill does not close on a click outside it**: the taskbar layer only sees clicks inside its input zone. It folds back on a click on its body, `CTRL + LEFT`, or when the taskbar hides or an overlay opens.
- **Activity pill gaps**: only music and Discord calls so far (no notifications, tray, timers); the Discord view shows no participants or speaking state; one MPRIS player at a time; not run on the Linux shell.
- **`CTRL + LEFT / RIGHT` are global**, so they shadow word-jump in every app while bound.
- **Two activity states after the engine merge (2026-11-08)**: `state/ActivityState.qml` drives the activity pill (mode, lead, music and calls from `Activities`), `state/Activity.qml` holds the notification and tray entries and an open screen nothing draws. They share the IPC target `activity` (pill: `next`, `previous`, `mode`, `rotate`; bar: `toggle`, `close`, `pin`, `current`) and the global shortcut `vados:activity` toggles a bar that has no surface. Fold `Activity` into `ActivityState` when the pill shows notifications and the tray.

- Lock tab module pills are 315 px wide and assume the free 22% of the settings body fits them; on screens narrower than about 1500 px they overlap the grid.

- **GitHub history box is empty.** The Profile tab draws the frame and the 26x7 cell grid only; no contributions are fetched (the network is reached only from files in the README Network section).
- **Profile picture is typed as a path.** Clicking the avatar shows a path field under the names, not a file dialog.
