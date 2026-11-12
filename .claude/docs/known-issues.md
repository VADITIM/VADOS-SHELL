# Known issues

- **The clipboard history, the 1.3 times expanded pill and the new leave are untested in Qt (2026-11-11).** This machine has no PySide6: `tst_clipboard`, `tst_gulp`, the new `tst_activity`, `tst_features` and `tst_preview` cases were written but not run; `utils/Clipboard.js` was checked with Node and `check-rules.py` passes. Nothing ran against a real `wl-paste` either (`quirks.md` § Clipboard history).
- **Ready budgets cover four engines (2026-11-10, clipboard 2026-11-11).** `tst_features` measures `Burst`, `Mutate`, the alert's and the clipboard's `Reshape`; the activity pill's expanded views and the Wi-Fi `Extension` are not measured against `Motion.budget.ready`, and the measurement is offscreen script time plus the animation clock, not a real compositor frame.
- **Planned surfaces have a row and a contract but no code** (`lock`, `widgets`, `canvas`); two points in `roadmap.md` § Still open wait for the user (the app manager's move action, keyboard focus for the V/AI widget).
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
- **Tray in the activity pill (2026-11-10)**: at most `activity.tray.columns` items (8), no tooltip, no status (`NeedsAttention` does not wake the pill), and `display()` of a menu at the cell's window position is unverified on a real compositor, as is the item's `icon` source.
- **Contract 1 is built except its checks on hardware (2026-11-10).** Built: the alert face, the source catalogue, swipe and tap, the bell and the tray inside the pill, `Activity` folded into `ActivityState`. `notifications.enabled` stays off by default (opt-in by `rules/security.md`, on by the roadmap; the user decides).
- **Notifications menu gaps (2026-11-10)**: rows show no time and no actions besides open; no drag and drop of files onto a device; devices are edited only in `shell.json`, not in settings; no transfer progress (contract 2, later); `Rising` bubbles are not used; not yet run on the Linux shell, so Blip, the portal chooser and the split's look are unchecked (`roadmap.md` § 2 Left).
- **Alerts gaps:** no app icon or image from the notification (the source glyph only); no actions besides open; a notification that peeks while an overlay holds the taskbar or the Wi-Fi extension is open is never drawn and its peek expires unseen (it stays in `Notifications.list`); in the `bare` style the alert has no body behind it; the expiry does not pause while the pointer is on the alert.
- **Untested on real hardware (alerts, 2026-11-10):** `Notifications.open` (the `default` action, `DesktopEntries.byId(desktopEntry)`), real `appName` / `desktopEntry` values from Discord, Vesktop, Telegram, ZapZap and browser web apps, and the alert over a covered taskbar on a real compositor.
- **Not yet on the gesture engine**: nothing left in the shell; new swipes (notifications, clipboard rows) must use `Gesture`.
- **Rendering cost is unmeasured on a GPU (2026-11-07).** `tst_rendering` proves which passes run (lite has no blur, an unshown layer runs none), not what they cost. Still to profile on real hardware: a full against a lite liquid and the extension's liquid stacked over the taskbar's while grown. Lite has no settings toggle yet (`rendering.quality` in `shell.json` only).
- **The shelved `shelf/dashboard-wave/Dashboard.qml` would not load as is**: `LiquidLayer` now requires `isShown`.
- **Supervision is untested in Quickshell (2026-11-07):** tested against a fake `Process` only. Unverified: that a command that cannot start flips `running` back to false (the supervisor counts that as `failed to start`), the `ping` exit when the network is down, `nmcli monitor` and `udevadm monitor` exits, and the `diagnostics` IPC returning multi-line text through `qs ipc call`. Hyprland's `hyprctl` queries and `Hardware`'s probe are not supervised (a poll repeats them) and fail silently.
- **Untested on real hardware (engines, 2026-11-07):** `OverlayWindow` keyboard hand-over between overlays, `StateFile` writes through `FileView.setText` and its `mkdir`, `Confinement.recover` on a live driftwm, `Notification.expireTimeout` being in seconds.
- **Untested on real hardware (notifications, 2026-11-06):** the `NotificationServer` registering, actions and images, and replacing a running mako or dunst.
- **Search has no rising bubbles**: its body spans the full screen height, so `Rising` (top and bottom surfaces to the screen edges) has no room.
- **The dashboard's top step is not a hit area**: the body `MouseArea` covers only the rectangle, so a click on the top step closes the dashboard. The bottom step (disk notch) has its own `MouseArea`.
- **The expanded activity pill does not close on a click outside it**: the taskbar layer only sees clicks inside its input zone. It folds back on a click on its body, `CTRL + LEFT`, or when the taskbar hides or an overlay opens.
- **Activity pill gaps**: music, Discord calls, notifications and the tray so far (no timers); the Discord view shows no participants or speaking state; one MPRIS player at a time; not run on the Linux shell.
- **`CTRL + LEFT / RIGHT` are global**, so they shadow word-jump in every app while bound.

- Lock tab module pills are 315 px wide and assume the free 22% of the settings body fits them; on screens narrower than about 1500 px they overlap the grid.

- **GitHub history box is empty.** The Profile tab draws the frame and the 26x7 cell grid only; no contributions are fetched (the network is reached only from files in the README Network section).

- **The shell cannot go below the Quickshell floor** (2026-11-11). Three windows with nothing in them are about 100 MB anonymous (one render thread and GL context per window) on top of the shared driver libraries; the three taskbars add about 60 MB. Sharing one context across windows (`QSG_RENDER_LOOP=basic`) was not tried: it renders every window on the GUI thread. Numbers and what was fixed: `decisions.md` § Memory.
- **The allocator options are not applied by the shell itself**: without the `MALLOC_CONF` line from the README the shell idles about 75 MB higher and keeps about 140 MB more after overlays were used.
- **The liquid's rim and fill are full-size textures of one colour** (`LiquidLayer` `rimTexture`, `fillTexture`): 8 MB of GPU memory each on a 1080p overlay while it is shown. A 1 x 1 `textureSize` would do; not changed because it needs a visual check of every liquid surface.
- **Task manager: no per-process network** (2026-11-11). Linux keeps no per-process byte counters without root (`nethogs`, eBPF); the NETWORK column shows `--` and only its header total (from `Traffic`) is real. Disk is `--` for processes of other users (`/proc/<pid>/io` is not readable).
- **Task manager is unverified on a real session** (2026-11-11): written on Windows without PySide6, so neither the preview nor `tst_processes` ran; `Processes.js` was checked with Node. Check the neck's place against the battery notch and the column's fuse at the edge on Linux.
- **Screenshot and recording are unverified on a real session** (2026-11-11): the preview tests drive the selection, drawing, copy, Esc, the recording notice, click to pause and hover to expand with mocked `Capture`; grim, `wl-copy`, gpu-screen-recorder and wf-recorder were not run from the shell. Check HiDPI cuts (the grab uses the frame's pixel size) and fractional scales.
- **The screenshot colour wheel and handles are unchecked on a real screen** (2026-11-11): the toolbar was seen live (black, vertical, at the pill), but the wheel, shape handles and drawing were only driven in the preview, which draws no liquid offscreen (`quirks.md`). An expanded activity pill is copied at its body size but without its expanded content.
- **The screenshot text tool is untested end to end** (2026-11-11): `Ink.js` text logic has a test, but the preview test could not load (another session's unfinished `dashboard/TaskTabs.qml`), so typing, the editor focus and a tap with `Gesture` threshold 0 (which may cross before it taps) are unchecked. Text hit boxes use an estimated Space Mono advance (`Ink.textAdvance`), not measured widths.
- **The search profile blob and the per-screen keyboard are unseen on a real screen** (2026-11-11): the blob's arc enter, splash, arc-and-slide leave and power column, the tinted best match and the app menu were checked only by the preview tests (which draw no liquid), and the keyboard hand-back when the pointer crosses monitors was not tried live. On Hyprland, whether `focusedMonitor` follows the pointer while an exclusive layer holds the keyboard is unverified. The larger type was not checked for overflow in every fixed-size row.
