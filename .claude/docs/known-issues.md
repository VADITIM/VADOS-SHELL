# Known issues

- **The shell holds about 845 MB resident on three screens** (2026-11-18, 960 MB before each overlay became one window, `decisions.md` § Overlays built ahead). Not a leak; without overlays it is about 695 MB, so the five overlay windows cost about 150 MB, settings the most (its banners). Opening an overlay on a screen of another size relays it out on the opening frame; all three screens here are 1080p, so that cost is not measured.
- **The taskbar clock redraws every second on every screen** (2026-11-18): the seconds roll keeps each taskbar window rendering about 30 frames a second, so the shell is never fully idle (each frame is cheap: under 1 ms on the render thread). A minute clock or a shorter roll would stop it; a design choice for the user.
- **Seven tests fail in the working tree as of 2026-11-18, outside the performance fix**: `tst_preview` (`NotificationMenu.qml` `fadeShare` undefined, `Motion.qml` lines 304 and 305 assigning undefined, a second interceptor on a prompt `TextInput`'s opacity), `tst_icons` (the `performance` path, the `animation` icon's rule), `tst_widgets` (three drag tests) and `tst_activity` (`test_clipboardStaysClosedInAMenu`).
- **The clipboard history, the 1.3 times expanded pill and the new leave are untested in Qt (2026-11-11).** This machine has no PySide6: `tst_clipboard`, `tst_gulp`, the new `tst_activity`, `tst_features` and `tst_preview` cases were written but not run; `utils/Clipboard.js` was checked with Node and `check-rules.py` passes. Nothing ran against a real `wl-paste` either (`quirks.md` § Clipboard history).
- **Ready budgets cover four engines (2026-11-10, clipboard 2026-11-11).** `tst_features` measures `Burst`, `Mutate`, the alert's and the clipboard's `Reshape`; the activity pill's expanded views and the Wi-Fi `Extension` are not measured against `Motion.budget.ready`, and the measurement is offscreen script time plus the animation clock, not a real compositor frame.
- **Planned surfaces have a row and a contract but no code** (`canvas`); two points in `roadmap.md` § Still open wait for the user (the app manager's move action, keyboard focus for the V/AI widget).
- **Catalogues are review-only.** Nothing checks that a settings tab or an activity key has its file; the `[features]` check stops at the surface (`tst_locking` checks that every `Lock.js` module has its `<Key>Module.qml`).

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
- **Wi-Fi 802.1X sign-in is PEAP with MSCHAPv2 only** (2026-11-17): networks that need EAP-TTLS, EAP-TLS (certificates) or an anonymous outer identity cannot be set up from the page, and a wrong method reads as WRONG PASSWORD. No CA certificate is set, so the server's certificate is not checked. A hidden 802.1X network is not provisioned (the script cannot tell its type before joining). The NetworkManager path is untested (no `nmcli` on the dev machine).
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
- **The login theme is unseen in a real SDDM session** (2026-11-13): it loads in `sddm-greeter-qt6 --test-mode` without warnings and renders offscreen with a mocked greeter, but installing it, a real login, multi-screen layout and the keyring unlock are unchecked.
- **Contract 5 additions are unseen** (2026-11-13): the new settings layout, the pop bar names, the per-level piece motion and both new tabs load without warnings (running shell and `tst_preview` `test_wholeShellLoadsWithoutWarnings`) but were not looked at. The font list is pointer only (Up and Down switch tabs), against the keyboard rule in `rules/interaction.md`. A right-hand taskbar mirrors the card and title direction through `Page.isMirrored`, unchecked.
- **Extension pages at pill width are unseen** (2026-11-13): the pages now get the hovered pill's width (about 230 px instead of 300), so long device or network names elide earlier; spacing was tightened but not checked by eye.

## Clearing the wallpaper leaves driftwm's background (2026-11-13)

On driftwm the compositor draws the picked wallpaper (`[background]`) and the shell draws none (`ownBackground`). Clearing `wallpaper.path` leaves driftwm's background on the last picked image, and a change of image has no crossfade there.

## One wallpaper for every screen (2026-11-13)

`wallpaper.path` is one image for all monitors; the roadmap wants one per monitor. Needs a per-screen key (or map) and a screen picker in the Wallpaper tab.

## The wallpaper folder is not searched recursively (2026-11-13)

`services/Wallpapers.qml` lists only the images directly in `wallpaper.folder`; images in subfolders are not offered.

## Settings choices are not reachable from the keyboard (2026-11-13)

Up/Down/Tab switch tabs and Left/Right the second bar, but the `OptionGroup`s, fields and the selection wheel take only the pointer (`rules/interaction.md` wants every overlay usable from the keyboard). The Wallpaper tab steps with PageUp/PageDown.

## Desktop widgets are only partly seen on a real session (2026-11-14)

Seen in a nested driftwm (winit backend, the shell with its own home): all six widgets draw above driftwm's wallpaper and take their layout from `shell.json`. Not checked, because nothing could move the pointer there: a widget taking a drag on the bottom layer, a canvas pan and zoom around it, an unplug and replug, and a fullscreen window stopping the updates. Smaller gaps: removing the last widget of a screen destroys its window at once, so that widget's leave is not seen; a screen counts as covered only while its fullscreen window has focus (`Compositor.activeWindow`); the disk widget shows the first disk only and the battery widget says `AC` on a desktop; the Widgets tab is pointer only, like the other settings choices.

## Displays tab (2026-11-15)

- **Mirroring and the `"*"` fallback entry are not offered**; the tab writes one entry per listed monitor.
- **Turning off the monitor that shows the settings reverts it** (2026-11-16): the overlay leaves with its screen, so KEEP is gone and the countdown puts the monitor back. Turn a monitor off from settings opened on another one.
- **Turning off a monitor between two others leaves a gap** the tab refuses until the rest are dragged together.
- **Upstream driftwm rejects `enabled`** (its `[[outputs]]` has `deny_unknown_fields`): on a driftwm without the local patch, turning a monitor off makes driftwm refuse the whole config until the countdown reverts it. The key is written only while a monitor is off.
- **The canvas is narrow below about 1600 px of screen width** (the controls column keeps its 420 px); seen in the 1280 x 800 nested session.
- **Arranging is pointer only**: Enter applies or keeps, but monitors cannot be moved and choices cannot be stepped from the keyboard (like the other settings choices).
- **The contract's liquid bodies are squircles** (`decisions.md` § Displays tab): adjacent monitors do not neck into each other.
- **The countdown shows only on the Displays tab**: with settings closed the layout still reverts at the deadline, but nothing on screen says so.
- **Hyprland is unrun**, and its kept layout needs the `source` line from the README.

## Lock screen (2026-11-14)

- **Unlocking is not run yet.** Seen in a nested driftwm (2026-11-14): `lock lock` locks and draws the screen, killing the shell leaves the output black and locked, a restarted shell locks again from its marker, and PAM `login` asks for the password. Typing the password, a wrong one, blanking and a second monitor are unchecked.
- **The leave starts from the bodies as drawn for the old size.** If the screen changed size during the lock, the leave's snapshot holds the cells of the old size; the bodies jump less than a cell, unchecked on hardware.
- **The first lock after the shell starts still creates the veil's render surface** (2026-11-18): the veil windows are kept from startup unmapped, so the first map pays the scene graph and shader setup once; later locks map an existing window. Not measured on the live session.
- **Module droplets may fuse in flight** (2026-11-17): the modules all leave one point on the wall, so two bound for neighbouring cells can neck together on the way before parting; their curves alternate sides, nothing keeps them apart beyond that.
- **Keys typed during the lock enter reach the focused window** (2026-11-17). The session lock engages about one second after the request, and the veil window has no keyboard (`check-rules.py` `[overlays]`), so a password typed straight after pressing lock goes to the app that had focus. Fix waiting on the user: let `LockWindow` take `keyboardFocus` while `Lock.isLocking` (and `WlrLayer.Overlay`, so a closing overlay never shows over the cut).
- **The lock veil is unrun on a real session** (2026-11-17): only offscreen tests. Unchecked: that driftwm really keeps the desktop and the veil on screen until the lock surface commits (read in `session_lock.rs`, `SessionLock::Pending`), that the lock surface's first frame matches the veil's last to the pixel, the stencil clip of the cut on real hardware, and Hyprland, which may paint something else between the request and the first lock frame.
- **Module contents vanish in the unlock frame.** Text and pictures live on the lock surface, so they go with it; the veil carries on with the bodies only.
- **No auto-lock.** Idle only blanks the locked screen (`decisions.md` § Lock screen); locking the desktop after idle or before suspend (logind `PrepareForSleep`, `loginctl lock-session` from elsewhere) does nothing in the shell yet.
- **The password field takes no cursor movement or input method.** Keys append, Backspace deletes, Escape and Ctrl+Backspace clear; dead keys and compose come through `event.text` but an input method popup is not supported on the lock surface.
- **Fingerprint and other PAM modules that need no answer are unsupported**: the conversation starts only on Enter with a non-empty password, and a second question ends it with AUTHENTICATION FAILED.
- **`Lattice.qml` does not load on Qt 6.12** (2026-11-15): `Final member top is overridden in class Lattice`, so `Settings` and `WidgetEditor` are unavailable and `tst_preview` and `tst_widgets` fail to compile (498 passed, 3 failed). The overridden `top` is not declared in `Lattice.qml`, `Piece.qml` or `Turn.qml`; not traced further.
- **Row hover colour is not animated in Audio and Network rows.** Only the Power icon fades (`Behavior on color`); the others switch at once. Left as is.

- The clipboard over an open menu has no liquid enter or leave (a flat panel, 2026-11-16), and the menu still owns the keyboard, so Escape may close the menu.

- **The boot screen keeps the accent it was switched on with** (2026-11-17): changing the accent does not redraw the splash or the Plymouth mark; switching the option off and on again does. Redrawing on every accent change would ask for admin rights each time.
- **The settings home page sometimes opens blank** (2026-11-17): once in about 20 live opens, right after several reloads in a row, the body, nav bar and clock came up but the banner and its version line did not (the area was empty, not faint). The real `Settings` module in system Qt (`qml6` with the preview mock tree) showed the banner every time: repeated opens, async loading, a window hidden until present, close and reopen at every gap up to 2.2 s, opening after a reload and reloading while open. Not reproduced since; cause unknown. `Masked` re-enabling `layer.enabled` was suspected for the profile picture but did not fail in a test.

## Pill frost shows only the wallpaper (2026-11-17)

- The frost behind the taskbar pills is the shell's blurred copy of `wallpaper.path`, not what is really behind them: an app window under a pill (an unfocused one; the focused one hides the taskbar) is not frosted, the wallpaper shows instead. Without a shell wallpaper (`wallpaper.path` empty, driftwm's own background) there is no frost.
- Overlay bodies (dashboard, search, settings, notifications) and the screenshot toolbar have no frost yet; their liquid layers take a `frostSource` when wanted.
- Assumes driftwm crops its `wallpaper` background like `PreserveAspectCrop` and that the frost lines up on a real session; not yet seen on screen. The extra cost (three window-sized textures and one blur while shown) is unmeasured on a GPU.
- **The password prompt is unseen with a real request** (2026-11-18): the keyring helper was checked against a Gcr client on a private bus name, the request logic and the overlay stacking by tests; polkit through `PolkitAgent`, picking another identity (only the default one is asked) and a keyring unlock in the running shell are unchecked.

## Keyboard tab (2026-11-19)

- driftwm takes one layout for every keyboard; overriding the built-in keyboard alone needs a per-device keymap in driftwm.
- Plain VIA boards (no Vial definition) show the ANSI fallback read only: VIA keeps the layout JSON outside the firmware, and loading one from a file is not built.
- No firmware flashing: compiled keymaps (`qmk flash`) and QMK boards without VIA or Vial are not programmed; `qmk` is not installed here.
- The keycode picker covers the basic HID codes, modifiers, media and (VIA protocol 12 and newer) MO and TG layers; mod-taps, macros, tap dance and Vial combos are not offered, and legends are US names, not the chosen xkb layout's characters.
- KLE rotation (`r`, `rx`, `ry`) and ISO enter shapes are drawn as plain rectangles.
- Without a udev rule granting the hidraw node (Vial's `59-vial.rules`), every read and write after READ AS ADMIN asks for the admin password once.
- Not tried on a session yet: the tab, the driftwm reload with a new layout, Hyprland's device names and a real Vial write.

## Tests (2026-11-19)

- PySide6 is not installed on the Linux machine, so `tools/tests/run.py` cannot start; the suite was run with `/usr/lib/qt6/bin/qmltestrunner` and a QML stand-in for `VadosTest`, which cannot write files, so `tst_statefile`, `tst_lock`, `tst_lockrecovery` and `tst_confinement` fail there for that reason only.
- `tst_preview` `test_favouritingAndHidingKeepTheOtherRows` fails at the favourite check (line 87); nothing changed on 2026-11-19 touches that path, cause not found yet.
