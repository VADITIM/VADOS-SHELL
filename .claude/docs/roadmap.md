# Roadmap

One roadmap for every feature of the shell. It combines the user's feature notes (Obsidian vault "VADOS Gallery", folder `SHELL`: `Refactor.md` is the brief; `Lock Screen`, `Notifications Menu`, `Alerts`, `Clipboard History`, `Native Monitor-Screen configurator`, `App Manager Tab`, `Widget`, `Settings`, `Additional`) with the work agreed before them. Mirrored to that folder as `Shell.md`.

Ordered by the phases of `direction.md` (user, 2026-11-07): engine integrity, then one complete vertical slice, then daily-driver features, compositor support and productization. Progress is measured by the foundations, not the feature count. Shipped items move to `decisions.md`.

## How to read it

- Every surface is a row in `shell/utils/Features.js` (`rules/features.md`): its `surface` kind, the taskbar part it is born from (`origin`), its `impact`, and whether it is built. A planned surface has an empty folder in `shell/modules/` waiting for it.
- Each planned feature below has a **contract**: what the note asks, what it is built on, what to build, its settings, capabilities and security, what is still open, and when it is done. An agent builds one contract at a time, following `architecture.md` § Features, and appends modules through the surface's catalogue.
- **Decided** points were settled by the user on 2026-11-10 (§ Decided); **Open** points are not decided yet (§ Still open), and nothing is built on them before the user answers.

## The registry today

| Feature | Row (`key`) | Surface | Born from | Impact | State |
|---|---|---|---|---|---|
| Taskbar | `taskbar` | bar | the screen edge | ambient | built |
| Activity pill | `activity` | mutation | the activity pill | glance | built: music, Discord calls |
| Extension (Wi-Fi) | `extension` | mutation | an idle pill | focus | built |
| Search | `search` | overlay | the taskbar column | focus | built; phase 2 finishes it |
| Dashboard | `dashboard` | overlay | the taskbar column | focus | built |
| Settings | `settings` | overlay | the taskbar column | takeover | built; tabs to add (contract 5) |
| Frame debugger | `framedebug` | debug | none | ambient | built |
| Alerts | `alerts` | mutation | the activity pill | glance | built: the alert face (2026-11-10); tray and entries left (contract 1) |
| Notifications menu | `notifications` | overlay | the taskbar column | focus | planned (contract 2) |
| Clipboard history | `clipboard` | mutation | the activity pill | focus | planned (contract 3) |
| Lock screen | `lock` | lock | the power pill | takeover | planned (contract 6); its layout editor is built |
| Widgets | `widgets` | desktop | none | ambient | planned (contract 7) |
| Canvas tooling | `canvas` | bar | the screen edge | ambient | planned (§ Next 6); needs `freeCanvas` |

## Phase 1: engine integrity (done in the preview)

Exit: transitions can be created, interrupted, reversed and chained without inconsistent visual or logical states.

- Shipped: liquid engine, motion tokens and reduced motion, overlay engine, gesture engine, transition lifecycle with recovery, shared geometry, compositor capabilities, persistence, enforced rules and tests; overlays joined with the lifecycles, leave geometry that follows screen changes, a measured script frame budget; subsystem interfaces and ownership (`interfaces.md`) with enforced import direction (2026-11-07); the feature registry, impact levels and ready budgets (2026-11-10).
- Left: verify on hardware and budget the render cost there (`known-issues.md`).

## Phase 2: vertical slice (taskbar and search)

Exit: search works as a finished daily-use feature, not an animation demonstration.

- Taskbar-to-search morph and return, keyboard and pointer, rapid input, error and recovery behaviour.
- **Verify on driftwm.** Run the shell in a real session and check every assumption in `quirks.md` § Unverified driftwm assumptions: camera centre, Y-up, fullscreen/pinned shapes, negative `move`.

## Phase 3: daily driver

Exit: normal daily computing without falling back to external shell utilities. The contracts are in build order; each one unlocks the next.

### 1. Alerts (`alerts`) and the rest of the activity pill

Note: `Alerts.md`. An alert is the activity pill growing into a bigger pill, liquid and with physics like everything else, for every notification, recognising the service it came from (Discord, WhatsApp, Telegram and any other).

- **Enter and leave**: the activity pill reshapes into the alert pill and back (`Reshape`, the `pill` character); a peek of several notifications is one pill. Potency follows urgency, decided only by `Attention`: low never peeks, normal is a glance, critical stays until dismissed.
- **Built on**: `state/Attention.qml` (`peek`, `held`), `services/Notifications.qml`, `state/Activity.qml` (`entries`), `ActivityPill` and `Reshape`, `Gesture` for the swipe that dismisses, `TypedText` for the text. VAD/OS BUBBLE (`C:\Users\vn\source\VADOS-BUBBLE`) has the first version; port it and bring it in line with V/AS.
- **To build**: `utils/Alerts.js`, the source catalogue (one row per service: how to recognise it from the notification's app name and desktop entry, its glyph and tint) with a test; `modules/alerts/Alerts.qml` drawn by the taskbar out of the activity pill; the system tray and notification entries inside the pill; fold `state/Activity.qml` into `ActivityState` (`known-issues.md`).
- **Settings**: `notifications.enabled` turns on by default once alerts draw them (`rules/security.md`: it replaces mako, dunst, swaync, so the README says so).
- **Done when**: a notification from each catalogued service peeks out of the pill on the focused screen, can be swiped away, opens its app on a tap, and is held under do-not-disturb and fullscreen; nothing is lost while held.
- **Built (2026-11-10)**: `utils/Alerts.js` (eight sources and `generic`, `tst_alerts`), the `alert` face of `ActivityPill` (`Reshape` to `Appearance.alerts`, ready inside the glance budget, measured in `tst_features`), `modules/alerts/Alerts.qml` over the pill body in `TaskbarWindow` (a swipe dismisses the peek, a tap opens through `Notifications.open`), the preview (`N`, `Shift+N`) and `tst_preview` cases. `architecture.md` § Alerts.
- **Left**: the system tray and notification entries inside the pill; fold `state/Activity.qml` into `ActivityState`; check on hardware against real Discord, Telegram and WhatsApp clients. **Open**: whether `notifications.enabled` turns on by default (§ Still open 3).

### 2. Notifications menu (`notifications`)

Note: `Notifications Menu.md`. A double split liquid burst: two pills with a wide gap between them, roughly 65 / 35. The top pill is the notification history, where every notification and alert is stored. The bottom pill is Blip Upload, with the four most recent files at its very bottom, ready to drag onto a device.

- **Enter and leave**: one burst that splits into the two bodies; the leave gives the taskbar back out of itself like the dashboard. `Burst` grows one body today, so the split is new engine work on `Burst` (a second form sharing one lifecycle), with a test in `tst_burst`.
- **Built on**: `OverlayWindow` and `Overlays` (the row is already an overlay on layer 1), `Burst`, `Rising`, `services/Notifications.qml`, `Gesture` for row swipes and the file drag.
- **To build**: `modules/notifications/NotificationMenu.qml` (root; `NotificationList`, `BlipTray`), `windows/NotificationMenuWindow.qml`, its `Variants` entry and IPC target; a `StateFile` `notifications` for the history; `services/Blip.qml` only where Blip is installed.
- **Settings**: `notifications.history` (how many are kept).
- **Security**: notification text is private; the history file holds what the notification daemon was given and nothing marked transient, and `clear` empties it. Blip reaches the network: a README Network row, and only while the menu is open.
- **Later** (user): device awareness, transfer progress and file previews in Blip Upload.
- **Decided**: it opens from the taskbar column like the dashboard, and the history is kept on disk across restarts (§ Decided 1, 2).
- **Done when**: the menu opens and closes from the keyboard and the pointer, history survives opening and closing, a file dragged from the tray reaches a device, and without Blip the bottom pill does not appear.

### 3. Clipboard history (`clipboard`)

Note: `Clipboard History.md`. The activity pill mutates into a wider, taller pill at the taskbar showing the last 6 clipboard entries, with up to 150 stored. A running activity sits at its far right as a bump that stays interactive and extends to the right. A click on an entry copies it without adding a new entry. Also asked: different looks for text, images, URLs and files; pinning; search over all 150; detecting sensitive content; a clear action.

- **Enter and leave**: `Reshape` on the activity pill body to the clipboard size, rows popping in from the centre outwards; the leave is its own, faster.
- **Built on**: `ActivityPill` (the body and the bump), `Reshape`, `Mutate`, `Gesture` (row swipe to delete, drag to scroll), `StateFile`, `Supervisor`.
- **To build**: `utils/Clipboard.js` (the history as pure logic: add, cap at 150, pin, pick without a new entry, search, clear, the kind of an entry, what counts as secret) with a test; `services/Clipboard.qml` (a supervised `wl-paste --watch`, `wl-copy` to pick; `wl-clipboard` is a dependency) with a preview mock; `modules/clipboard/ClipboardHistory.qml` and one row type per kind; IPC `clipboard toggle | clear` and `SUPER + V`.
- **Settings**: `clipboard.enabled` (opt-in: it reads everything copied), `clipboard.size` (150).
- **Security** (`rules/security.md`): entries offered with `x-kde-passwordManagerHint: secret` and entries from password managers are never stored; detected secrets (keys, tokens) are shown masked and never written to `~/.cache/vados`; images are stored only if the user turns that on.
- **Decided**: pointer only (click, wheel, drag); `SUPER + V` only opens and closes it. Search over the 150 entries waits for a keyboard owner and is not in the first version (§ Decided 3).
- **Done when**: copying in any app adds a row, picking a row pastes it elsewhere without a duplicate, 151 entries leave 150 with pinned ones kept, a password-manager copy never appears, and history survives a shell restart.

### 4. System controls: audio routing and power profiles

Proposed in `Additional.md` and taken as good suggestions (§ Decided 9); both are in `direction.md` phase 3 ("audio and brightness controls", "network and battery").

- **Audio routing**: the audio idle pill grows an `Extension` page (like the Wi-Fi page): output and input devices, per-stream volume, dragging a stream onto a device. Built on `services/Audio.qml` (PipeWire is already bound for volume and for Discord's streams) and `modules/extension`. To build: `modules/extension/AudioPage.qml`, stream and device lists in `Audio`.
- **Power profiles**: Performance, Balanced and Power Saver from the battery idle pill or the dashboard's battery notch, through `power-profiles-daemon`. To build: profile reading and setting in `services/Battery.qml` (or a `Profiles` service), a three-way control; the liquid tints by profile only if the user wants it.
- **Brightness** is in `direction.md` and in no note: a slider on the same extension pattern.

### 5. Settings: the remaining tabs

Note: `Settings.md`. The sweep, the accent navigation pop bar, the second pop bar, User, Pills, Taskbar and the lock layout editor are built (2026-11-09). Left, each a tab added through `Settings.tabs` / `subTabsByTab` and a `Page` of `Piece`s:

- **System font** (Customization): changes the font of the whole system, not only the shell. To build: a font list (fontconfig), a service that writes the user's fontconfig, GTK and Qt font settings and can put the previous ones back. Opt-in and reversible: it takes over a system role (`rules/security.md`). Key `appearance.systemFont`.
- **Link to VAD/OS** (Advanced): detect installed VAD/OS apps from their desktop entries. Installed: offer to make them the default apps (through `xdg-mime`), one confirm per app. Not installed: their icons and GitHub release links. Opening a link uses the browser; the shell itself fetches nothing.
- **Services** (Advanced): Media Player is built; Blip joins with contract 2.
- **Backgrounds** (Customization): the wallpaper per monitor. Needs a background layer window, which the widgets layer (contract 7) is the sibling of; build them together.
- **Displays** (note `Native Monitor-Screen configurator.md`): arrange, scale, rotate, set resolution and refresh rate, so no AUR tool (wdisplays, nwg-displays) is needed. The shell finds out by itself how to apply and persist it per compositor. To build: `Compositor.outputs` and `Compositor.applyOutputs(layout)` (the only place that talks to the compositor: driftwm's config, Hyprland's `monitor` rules, `wlr-output-management` elsewhere), a new capability `outputConfiguration` in `utils/Platform.js` and the README table, `modules/settings/DisplayEditor.qml` (monitors as draggable liquid bodies on a canvas, `Gesture`), a keep-or-revert countdown after applying so a bad mode never strands the user. **To verify**: driftwm's output configuration syntax and whether it reloads live.
- **Apps** (note `App Manager Tab.md`): three groups, top to bottom: launchable apps, AUR packages, dependencies. Per entry: open its folder in the file manager, move it, delete the program with all its files. To build: `services/Packages.qml` (reads `pacman` only while the tab is shown; mock for the preview), `modules/settings/AppManager.qml`. **Decided**: delete is `pacman -Rns` of the chosen package, after one confirm, through the system's own authentication prompt (§ Decided 5). **Open**: what "move it" means (§ Still open 1).
- **V/AI** (note `Widget.md`): the tab that connects the agent widget; contract 8.
- **Decided**: Displays, Apps and V/AI are the second bar of the existing `SETTINGS` tab (§ Decided 6).

### 6. Lock screen (`lock`)

Note: `Lock Screen.md`. Everything on the taskbar merges at the power pill and slings to the screen centre; there the pill fills with liquid, expands and pops into the lock screen's modules and widgets, each slung to its place with a very small stagger in random order, however many there are. The desktop is covered by the chosen lock background, heavily blurred. On unlock every pill moves to the centre of the taskbar and bursts out towards its edges, the leftover liquid evaporates and the taskbar is back. Layout on a grid; three required modules (User Profile, Login Window, Time / Date) and optional widgets (weather, music player, mini dashboard, notifications, more to come). On the lock screen the activity pill is horizontal, a small bump above the user icon. After a time without input the screen turns off; that time is a setting, not hardcoded (user: 1 minute by default).

- **Security first** (`rules/security.md`, and the note's own demand): the lock is `WlSessionLock` in `windows/LockWindow.qml` and nothing else; authentication is `PamContext` in `services/Lock.qml` and nowhere else; unlocking never waits on an animation; a shell crash leaves the session locked. **Before any code: confirm driftwm implements ext-session-lock** and add `sessionLock` to `utils/Platform.js` and the README table. Without it the feature does not exist there; a plain overlay is never a lock.
- **Built on**: `utils/Lock.js` (the module catalogue and 16 x 16 placement, built) and the `lock.layout` / `lock.wallpaper` keys with their editor in settings (built); `Gather` for the merge at the power pill; `Mutate` per module; `Lifecycle`; `services/Power.lock()` as the entry point.
- **To build**: `windows/LockWindow.qml`, `services/Lock.qml`, `modules/lock/LockScreen.qml` (root: grid, enter and leave) and one file per catalogue module (`ClockModule`, `ProfileModule`, `LoginModule`, then the widgets); a rendering component for the blurred background (it joins `RENDERING_COMPONENTS`, `rules/performance.md`); the sling as a `Motion.liquid` character, not its own physics; idle blanking.
- **Settings**: `lock.blankAfter` (seconds, default 60, 0 for never), beside `lock.layout` and `lock.wallpaper`.
- **Multi-monitor**: every screen is locked; modules sit on the focused screen, the others show the background. A hotplug while locked re-places the layout and never reveals the desktop.
- **To verify**: driftwm's ext-session-lock and how it powers a display off (output power management, or its own IPC); Quickshell's idle notification on driftwm.
- **Done when**: lock and unlock work from the power pill, the keyboard and IPC; a wrong password and a PAM failure are shown and logged; killing the shell while locked keeps the session locked; the screen blanks after the configured time and wakes to the lock.

### 7. Widgets (`widgets`)

Note: `Widget.md`. A mix of how macOS handles widgets and how the shell draws: placed per monitor, in front of the desktop and always behind app windows, never hidden the way the taskbar is. On driftwm their position is tied to the screen, not to the canvas, so panning the canvas never loses them.

- **Enter and leave**: each widget pops in on its own (`Mutate` / `Turn`); the layer itself is ambient and never enters on request. Idle motion stops under reduced motion and while a fullscreen window covers the monitor (`rules/performance.md`: idle costs nothing).
- **Built on**: the grid placement of `utils/Lock.js` (shared once widgets use it: move the placement maths into its own utility then, with a line in `decisions.md`), `Gesture` for moving a widget, `Squircle`, the dashboard's readouts as the first widgets.
- **To build**: `utils/Widgets.js` (the catalogue: key, label, size) with a test; `windows/WidgetWindow.qml` (one per monitor, the layer below app windows); `modules/widgets/WidgetLayer.qml` (root) and one file per widget; a Widgets tab in settings to place them.
- **Settings**: `widgets.layout` per monitor name.
- **Multi-monitor** (also raised in `Additional.md`): layouts are stored per monitor; a monitor that comes back gets its layout back, a new one starts empty, and a changed resolution or scale re-places widgets inside the screen.
- **Decided**: a widget is fixed to its monitor wherever the canvas camera is (§ Decided 7).
- **Done when**: widgets survive a canvas pan, a monitor unplug and replug, and a shell restart; none is ever above an app window.

### 8. V/AI agent widget

Note: `Widget.md` § AI Agent Widget. A small agent buddy, animated with expressions and actions: quick access to the user's AI model (an API key, a local model, or a subscription), not a replacement for a full client. It powers down most of what it uses after 5 minutes idle. First: the Claude subscription, switching between Chat and Code and between chats and sessions. Settings gets a tab "V/AI - VAD/OS AI" to connect the key, local model or subscription.

- **Built on**: the widgets layer (contract 7: the agent is a row in `utils/Widgets.js`), `TypedText` for answers, `Supervisor` for the backend process, `Motion.isReduced` for the buddy's idle motion.
- **To build**: `services/Agent.qml` (one interface over three backends; the process starts on first use and stops after `agent.idleAfter`), `modules/widgets/AgentWidget.qml` (buddy, expressions, the conversation), the V/AI tab.
- **Settings**: `agent.enabled` (opt-in, off), `agent.backend` (`subscription`, `key`, `local`), `agent.idleAfter` (seconds, default 300), `agent.localAddress`.
- **Security** (`rules/security.md`): a secret never touches disk through the shell, so the API key is not a `shell.json` key and not a `StateFile`; the README Network section lists `services/Agent.qml` with each host it reaches, and it reaches them only while the widget is in use.
- **Decided**: the API key lives in the system keyring and the subscription is reached through the user's own Claude client (§ Decided 4). **Open**: typing into a widget needs keyboard focus on the desktop layer (§ Still open 3).
- **Done when**: a question typed into the buddy is answered through the chosen backend, the backend process is gone after the idle time and back on the next question, and no credential is in `shell.json` or `~/.cache/vados`.

## Phase 3, continued: agreed before the notes

5. **Desktop mode, Windows parity:**
   - Aero-snap by dragging a window to a screen edge or corner, with a liquid preview of the target region.
   - Super+Up/Down cycle (restore → maximize → minimize).
   - Remember each window's restore geometry across maximize.
   - Show desktop (Super+D parks everything, again restores).
   - Alt+Tab switcher as a liquid pill strip.
6. **Canvas mode tooling** (`canvas`, needs `freeCanvas`):
   - Minimap pill of the infinite canvas (windows as droplets, viewport as a lens).
   - Bookmarks exported to the taskbar as liquid tabs.
   - Recenter and zoom-to-fit controls in the activity pill.
7. **Mode transition animation.** Switching Canvas ↔ Desktop gets a named V/AS motion: windows fly to their parked or restored spots; the camera eases home.

## Phase 4: compositor support

Complete the driftwm adapter and the other backends on `Compositor.capabilities` (the contract and the README "Compositor support" table shipped 2026-11-07). Left: test each backend for real, focus tracking on generic Wayland, and the capabilities the contracts above add (`sessionLock`, `outputConfiguration`).

## Phase 5: productization

Installation and upgrade, configuration validation and migration (shipped), logging and diagnostics (shipped), documentation, release policy, real-world testing.

- **Crash recovery** (raised in `Additional.md`): runtime state is already saved as it happens through `StateFile` and recovered on start (`rules/state.md`), and the session lock survives a shell crash by protocol, so no separate dump before each burst is needed. What is missing is the restart itself: a systemd user unit with `Restart=on-failure`, shipped with the install.

## Later

- **User profiles** (agreed 2026-11-06): several profiles with name and picture, chosen in settings. Today a single `profile` in `shell.json` feeds the search circle.
- **More abilities**: the taskbar carry as a drag ability, a right click ability, `Jolt` on more surfaces.
- **Dashboard wave**: the shelved pour-out wave and idle ripple (`shelf/dashboard-wave/`) could return as an option.
- **Dashboard follow-ups**: real icons, a widget in the `[EMPTY]` slot, quick settings with drag-only sliders (V/AS `components/13-dashboard.md`), weather unit and day names.
- **Media** with a wave level, inside the activity pill.
- **Search**: calculator and file results, actions ("shutdown", "settings"), drag a result tile onto the taskbar to pin it.
- **Unified icon set** stored in V/AS, replacing the theme lookup.
- **Per-compositor blur** for driftwm through layer rules once its layer-rule syntax is confirmed.
- **Screenshot interface** in the style of Lightshot: instant region select, fast and smooth.
- **Text action pill** (proposed in `Additional.md`, kept for later, § Decided 9): a small pill with actions for selected text (translate, explain through V/AI, search the clipboard history). Wayland does not show the shell another app's selection, only the primary selection where the compositor offers data control, so this is feasible as actions on the primary selection and on clipboard entries, and belongs after contracts 3 and 8.

## Decided

Settled by the user on 2026-11-10; the contracts above are built on these.

1. **The notifications menu opens from the taskbar column**, like the dashboard (the row's `origin: "column"`). The older alert band pulled from the top edge is dropped.
2. **Notification history is kept on disk** across restarts, in a `StateFile` (`~/.cache/vados/notifications.json`). It holds message text, so `clear` empties it and nothing marked transient is stored.
3. **Clipboard history is pointer only** (click, wheel, drag). `SUPER + V` opens and closes it; arrows and type-to-search are not built until a later engine decision gives a `mutation` a keyboard owner.
4. **V/AI credentials** (the user left the choice open; chosen as the safest): the API key goes into the system keyring (Secret Service), never into a file the shell writes; the subscription is reached through the user's own installed Claude client, which holds its own login, so the shell stores no credential at all.
5. **The app manager's delete is `pacman -Rns <package>`** of the chosen app: the package, its configuration and the dependencies nothing else needs. One confirm per removal that names what goes with it; root comes from the system's own authentication prompt (polkit), never a stored password. Files in the home directory are not touched.
6. **Displays, Apps and V/AI sit in the existing `SETTINGS` tab** as its second bar (`subTabsByTab.settings`); no new main tab.
7. **Widgets are fixed to their monitor** wherever the canvas camera is. The older idea of driftwm `widget = true` windows that follow the camera is dropped.
8. **The ready budgets stay** (`Motion.budget.ready`: glance 250 ms, focus 500 ms, takeover 500 ms).
9. **`Additional.md`: good suggestions are taken, the rest is replaced.** Taken: audio routing, power profiles and brightness (contract 4), display hotplug handling (contracts 6 and 7), restart after a crash as a systemd user unit (phase 5). Kept for later: the text action pill. Replaced: its `/tmp` state dump before each burst, by `StateFile` (`rules/state.md`).

## Still open

1. **"Move it" in the app manager.** `pacman` cannot move an installed package; the tab is built without a move action until the user says what it should do.
2. **Keyboard focus for the V/AI widget.** Typing into a widget needs focus on the desktop layer, which the `desktop` surface kind does not grant; an engine change to decide when contract 8 is built.
3. **The notification daemon by default.** Contract 1 says `notifications.enabled` turns on once alerts draw them; `rules/security.md` says every system role is opt-in and starts off. It stays off until the user picks one.
