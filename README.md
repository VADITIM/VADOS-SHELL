# VAD/OS Shell

A desktop environment for Wayland, written in [Quickshell](https://quickshell.org) (Qt 6 / QML) on V/AS (VAD/OS APPLICATION SYSTEMS). It is more than a rice: taskbar, search, dashboard, settings and window management are one liquid system, not separate widgets. Everything grows out of the taskbar edge, fuses with its neighbours and flows back into it.

It targets [driftwm](https://github.com/malbiruk/driftwm) first and stays usable on Hyprland and on any wlroots-style compositor.

- **Taskbar** on the left or right edge in three styles, with foldable idle pills (power, audio, battery, network, USB, tray, clock).
- **Search** as a full-height liquid column: fuzzy app search, pinned apps, best match, profile and power.
- **Dashboard** with CPU, GPU, RAM, disk, battery and a seven-day weather forecast.
- **Settings** that open from the taskbar: accent colour, taskbar style and side, window mode.
- **Window modes** on driftwm: free infinite canvas, or a Windows-style desktop with snap, maximize and minimize.
- **Live config** in one `shell.json`.

## Install

Clone into `~/.config/vados` and start the shell with `qs -p ~/.config/vados/shell`. What to install, and what each feature needs, is in [dependencies.md](dependencies.md).

### driftwm (primary)

`~/.config/driftwm/config.toml`:

```toml
autostart = ["qs -p ~/.config/vados/shell"]

[keybindings]
"super" = "spawn qs -p ~/.config/vados/shell ipc call search toggle"
"ctrl+p" = "exec qs -p ~/.config/vados/shell ipc call settings toggle"
"super+d" = "spawn qs -p ~/.config/vados/shell ipc call dashboard toggle"
"super+n" = "spawn qs -p ~/.config/vados/shell ipc call notifications toggle"
"super+v" = "spawn qs -p ~/.config/vados/shell ipc call clipboard toggle"
"super+a" = "exec qs -p ~/.config/vados/shell ipc call desktop toggle"
"super+up" = "exec qs -p ~/.config/vados/shell ipc call desktop maximize"
"super+down" = "exec qs -p ~/.config/vados/shell ipc call desktop minimize"
"super+left" = "exec qs -p ~/.config/vados/shell ipc call desktop snap left"
"super+right" = "exec qs -p ~/.config/vados/shell ipc call desktop snap right"
"f11" = "exec qs -p ~/.config/vados/shell ipc call desktop fullscreen"
"ctrl+right" = "exec qs -p ~/.config/vados/shell ipc call activity next"
"ctrl+left" = "exec qs -p ~/.config/vados/shell ipc call activity previous"
"print" = "exec qs -p ~/.config/vados/shell ipc call screenshot shoot"
"shift+print" = "exec qs -p ~/.config/vados/shell ipc call recording toggle"
"kp_0" = "exec qs -p ~/.config/vados/shell ipc call frames toggle"
"kp_add" = "exec qs -p ~/.config/vados/shell ipc call frames shot"
```

Check the keybinding table name against your driftwm version's `config.reference.toml`.

Without the `print` and `shift+print` lines driftwm runs its own defaults: PRINT copies the whole screen silently with `grim`, and SHIFT+PRINT starts `slurp`, a white selection that closes on release. Bind both so the shell's screenshot and recording take the keys.

### Hyprland

```
exec-once = qs -p ~/.config/vados/shell
bind = SUPER, G, global, vados:search
layerrule = blur, vados-search
layerrule = ignorezero, vados-search
bind = CTRL, P, global, vados:settings
layerrule = blur, vados-settings
layerrule = ignorezero, vados-settings
bind = SUPER, A, global, vados:dashboard
layerrule = blur, vados-dashboard
layerrule = ignorezero, vados-dashboard
bind = SUPER, N, global, vados:notifications
bind = SUPER, V, global, vados:clipboard
bind = CTRL, right, global, vados:activityNext
bind = CTRL, left, global, vados:activityPrevious
bind = , Print, global, vados:screenshot
bind = SHIFT, Print, global, vados:record
bind = , KP_0, global, vados:frames
bind = , KP_ADD, global, vados:frameShot
```

### Memory

Start `qs` with these allocator options. Quickshell uses jemalloc, which by default keeps the memory the shell frees and lets the kernel round it up to huge pages; with them the shell idles about 75 MB lower and gives memory back after an overlay closes.

```toml
autostart = ["env MALLOC_CONF=thp:never,narenas:4,background_thread:true qs -p ~/.config/vados/shell"]
```

```
exec-once = env MALLOC_CONF=thp:never,narenas:4,background_thread:true qs -p ~/.config/vados/shell
```

The options must be in the environment before `qs` starts; a `//@ pragma Env` line in `shell.qml` is too late. Key bindings that call `qs ... ipc call` do not need them.

On a machine with an NVIDIA GPU whose screens all run on the AMD or Intel GPU, adding `__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json` to the same `env` keeps NVIDIA's EGL libraries out of the shell (about 100 MB resident). Leave it out when a screen is driven by the NVIDIA GPU.

Overlays (search, settings, dashboard, notifications menu) are built when they open and destroyed when they have left, per screen, so an overlay nobody uses costs nothing.

### Anything else

Bind keys to `qs -p ~/.config/vados/shell ipc call search toggle`, `... settings toggle` and `... dashboard toggle`. The taskbar hides only when the focused window is fullscreen or maximized, because plain Wayland gives no window geometry.

## Compositor support

The shell asks the compositor what it can do (`shell/utils/Platform.js`) and never which one runs. Taskbar, search, dashboard, settings and the liquid work everywhere (core); window information needs `windowGeometry` (extended); window modes need `freeCanvas` and `windowControl` (native).

| Capability | driftwm | Hyprland | Other Wayland | Without it |
|---|---|---|---|---|
| `activeWindow` | yes | yes | yes | Other Wayland knows the focused window only while it is fullscreen or maximized. |
| `windowGeometry` | yes | yes | no | The taskbar hides only for a fullscreen or maximized window, not for one that reaches its edge. |
| `fullscreenDetection` | yes | yes | yes | Fullscreen windows would not hide the taskbar or hold notifications. |
| `focusTracking` | yes | yes | no | Shortcuts, IPC calls and notification peeks open on the first screen instead of the focused one. |
| `windowControl` | yes | no | no | No window modes; the `desktop maximize` and `desktop fullscreen` IPC calls do nothing. |
| `windowMinimize` | yes | no | no | No minimize; on driftwm it is emulated in Desktop mode by parking the window off-screen. |
| `windowSnap` | yes | no | no | No snap; on driftwm only in Desktop mode. |
| `workspaceManagement` | no | no | no | No backend has it yet; the shell shows no workspaces. |
| `freeCanvas` | yes | no | no | No Canvas and Desktop window modes; the settings tab hides the mode buttons. |
| `layerShell` | yes | yes | yes | Required: the shell cannot run without wlr-layer-shell. |

Keys: Hyprland reads the `vados:*` global shortcuts; driftwm and other compositors bind the `ipc call` commands. `tools/check-rules.py` fails when this table and `Platform.js` disagree.

## Window modes (driftwm)

The Desktop tab in settings switches between two modes (`shell.json` key `desktop.mode`):

- **Canvas** — driftwm as it ships: an infinite canvas with a free camera.
- **Desktop** — the screen behaves like a Windows desktop:
  - Switching to Desktop minimizes every window except the focused one.
  - The camera is locked at zoom 1 and windows stay inside the screen.
  - New windows open cascaded on the screen.
  - Clicking a taskbar app restores it if minimized, focuses it if it is in the background, and minimizes it if it is already focused.
  - Maximize, snap, minimize and fullscreen are available through the IPC calls above.

Switching back to Canvas restores every minimized window to where it was.

## Search

`SUPER + G` opens the app search: the taskbar streams into a circle at the edge, which bursts into a full-height liquid column. Results run down its left side from the top, the best match swells out of the middle of the wall, and the field is at the bottom. Near the top a droplet shoots out of the wall and bursts into your profile: your picture in a liquid blob, your name below it (click either to edit your profile in settings) and the power options (lock, suspend, restart, shut down; restart and shut down ask twice) stacked close on its left. The best match is tinted with its app's own colour. Type to fuzzy search. Arrows and Tab move, Enter opens, Esc clears and then closes. Right click (or the Menu key) opens a small menu to favourite an app (favourites lead the list while the field is empty) or hide it; the grey HIDDEN at the very bottom (or Ctrl+H) shows hidden apps again.

## Taskbar

Drag down on the idle pills to fold them to power, audio and a small dot; drag up, or press the dot, to unfold them.

## Activity pill

A liquid pill in the middle of the taskbar shows what is running now. It has four states:

- **Hidden**: gone.
- **Idle**: a small bead, nothing happening.
- **Active**: a capsule with the leading activity (Spotify or any MPRIS player with live bars, a Discord voice call with the mic state). Other running activities hang under it as small droplets; scroll on the pill to bring the next one to the front.
- **Expanded**: the pill spreads from the taskbar towards the screen into that activity's own shape. Music: a disc with the cover and a progress ring, title, artist, previous / play / next. Discord: the call time, with mic and deafen droplets hanging under it. Recording: the time, Pause or Resume and Stop (see Screenshot and recording).

`CTRL + RIGHT` steps up (hidden, idle, active, expanded), `CTRL + LEFT` steps down; a click on the pill steps up too, and a click on the expanded body folds it back. It turns active on its own when something starts and idle when everything stops. IPC: `ipc call activity next`, `previous`, `mode <name>`, `rotate`.

`CTRL + LEFT` / `RIGHT` are global bindings, so they shadow word-jump inside apps. Rebind them in the compositor config if that matters to you. Discord's mic and deafen mute Discord's own PipeWire streams, so Discord's interface does not show them.

## Screenshot and recording

**PRINT** freezes the screen and darkens it at once. A copy of the activity pill grows straight away along the taskbar into a black toolbar, so you can pick a tool before choosing an area. Drag to select an area; drag inside it to move it, drag its corners to resize it, drag outside it to select another, and tap outside it to move it there (a tap never closes the screenshot). The toolbar:

- **Select**: move and resize the area; drag a shape by its outline (or a text) to move it; tap a text to edit it.
- **Color**: a colour wheel with a brightness slider pops out of the pill; click the tool again or anywhere to put it away.
- **Paint**: draw freely, anywhere on the screen, so moving or resizing the area later keeps your drawing.
- **Erase**: wipe away what you drew (a ring shows its reach).
- **Shape**: picking it switches to drawing at once, and droplets for box, circle, line and arrow pop out; drag anywhere to draw one. Every shape stays editable: drag a corner (or a line's end) to reshape it, drag its outline to move it.
- **Text**: tap anywhere to type there in large bold text with a dark outline; Enter or Esc finishes (Shift+Enter for a new line), tap a text to edit it again, drag it to move it. An empty text disappears.

**Ctrl+C**, **Ctrl+S** or Enter copies the area with your drawing to the clipboard, saves it as `Screenshot_<date>_<time>.png`, the screen fades back and the activity pill says COPIED. **Esc** fades back without copying. **Ctrl+A** selects the whole monitor, Ctrl+Z undoes the last stroke, Tab and Shift+Tab switch tools, the arrows nudge the area (Shift for 10 px). Ctrl+C without an area copies the whole screen. It needs `grim` (and `wl-copy` for the clipboard).

**SHIFT + PRINT** starts recording the screen you are on. The activity pill says RECORDING NOW, and a moment later becomes a recording pill with the time and a softly pulsing dot. Click it to pause (the dot turns into a pause sign) and again to resume. Hover it for a moment to open its controls: Pause or Resume, and Stop; move away and it folds back. SHIFT + PRINT again stops too. Recordings are saved as `Recording_<date>_<time>.mp4`. It uses `gpu-screen-recorder` (pauses, records desktop audio) or else `wf-recorder` (no pause, no audio).

Both save to the folders in Settings > Settings (`capture.screenshots`, `capture.recordings`); empty means `~/Pictures/Screenshots` and `~/Videos/Recordings` (or your `XDG_PICTURES_DIR` and `XDG_VIDEOS_DIR`). IPC: `qs -p ~/.config/vados/shell ipc call screenshot shoot | close`, `... recording toggle | pause | stop | status`.

## Settings window

The gear above power or `CTRL + P` opens the settings: the taskbar melts into a circle that sweeps across the whole screen as a liquid burst, bounces on the far edge and settles into a body merged with the screen edges. The taskbar becomes the main navigation inside it, a tall accent-coloured pop bar with User, Settings, Customization and Advanced; tabs with deeper levels open a white second pop bar to its right (Customization: Backgrounds, Pills, Taskbar, Lock Screen; Advanced: Link to VAD/OS, Services). Up/Down/Tab switch tabs, Left/Right the second bar. Esc, `CTRL + P` or a click outside closes it: the body collapses back into the taskbar.

`CTRL + P` is a global binding, so it shadows Ctrl+P (print) inside apps. Rebind it in the compositor config if that matters to you.

## Dashboard

A click on the taskbar clock (or `SUPER + A`, or `ipc call dashboard toggle`) streams the taskbar into a new circle at the taskbar's position, fused to the screen edge, which bounces out along the dashboard with waves crashing onto its walls, with bubbles rising off it. It shows:

- CPU and GPU: temperature as the ring around the chip, load as the percentage inside it (the chip turns the load's colour). The GPU's curved line at its top left is VRAM.
- RAM: a chip ring tracking used memory, with used/total GB under it.
- Disk: in the notch at the bottom, fill bar and used/total GB. Tap the disk icon to page through disks.
- Battery (laptops only): a vertical battery in a notch on the far side, filled and coloured by charge (red under 10%, orange under 20%, yellow under 40%, lime under 60%, green above), green with a bolt while charging.
- Task manager: once the dashboard has opened, a pill grows out of its far side, runs to the far screen edge and fuses with it as a tall column. Two tabs: **Processes** (every running program, grouped by name, with CPU, memory, disk and network; the column headers show the totals) and **App history** (CPU time, peak memory and disk I/O per program, kept across restarts in `~/.cache/vados/apphistory.json`). Click a column header to sort by it, again to flip the order. Right-click a row for **Kill** (SIGTERM to every process of the row), **Open** (focuses its window, or starts it) and **Find path** (shows the program in your file manager). Keyboard: up and down select, left, right or Tab switch tabs, Menu or Shift+F10 opens the row menu, Enter opens, Delete kills. Disk needs read access to `/proc/<pid>/io`, so it shows `--` for other users' processes; per-program network is not measured yet (`--`). It needs `python3`; Find path uses `gdbus` (`org.freedesktop.FileManager1`) and falls back to `xdg-open` on the folder. The grid button beside NAME shows each program's icon in taller rows (`dashboard.taskIcons`). Hidden when the screen is too narrow for it.
- Weather now and for the next six days, from [Open-Meteo](https://open-meteo.com). Set a city with `qs -p ~/.config/vados/shell ipc call dashboard location "Berlin"`; empty guesses the location from your IP (ipinfo.io).

Bars and rings are colour-coded in bands: your accent colour while the reading is normal, then yellow, orange, red. GPU readings need `nvidia-smi` (NVIDIA) or the amdgpu driver (AMD). Esc or a click outside closes it.

## Activity and notifications

With `notifications.enabled` on, every notification that may interrupt (critical always; normal ones unless do-not-disturb is on or a window is fullscreen; low never) grows out of the activity pill as an alert: the app it came from (Discord, Telegram, WhatsApp, Signal, Slack, Element, Thunderbird and Spotify are recognised; anything else shows its own name), the summary and the start of the message. Several arriving together share one alert (`+N`). Hover it to open the whole notification, image included; it stays while hovered and goes 1.2 s after the pointer leaves. Click it to open the app, swipe it sideways to put it away; it stays in the notifications menu either way.

Unread notifications keep the activity pill active with a bell and their count; clicking the bell opens the notifications menu. Scroll on to the dots for the system tray: click an icon to activate it, right-click for its menu.

### Notifications menu

`SUPER + N` (or the bell) bursts a full-height liquid column out of the taskbar, which splits in two. The upper body is the history: every notification the shell received, newest first, kept across restarts (up to `notifications.history`; transient ones are not kept). Each row shows the app, the group or sender and the message. Click a row to open its app, swipe it sideways to remove it. A trash bubble beside the wall clears everything, and a mute bubble turns do-not-disturb on and off. Opening the menu marks everything read.

The lower body sends files with [Blip](https://blip.net) and appears only while Blip is installed. Your devices from `send.devices` show as circles. Pick one, then press SEND: the menu closes, your file chooser opens (the desktop portal), and each chosen file goes to that device (`blip --peer=<peer> --file=<file>`). With no device picked, the files open in Blip's own window. The gear bubble picks the sending app; Blip is the only one so far.

Keys: Tab moves between the list, the bubbles and the send tray; arrows move, Enter or Space presses, Delete removes a row, Esc closes.

### Clipboard history

On by default (`clipboard.enabled`), `SUPER + V` grows the activity pill into a bigger pill beside the taskbar with your last six copies, pinned ones first. Text, links, files and images each look different; a copy that looks like a key, token or password is shown as dots and is never written to disk, and a copy a password manager marks as secret (KeePassXC and others that set `x-kde-passwordManagerHint`) is never kept at all. Click an entry to copy it again (it moves to the top, no duplicate), scroll to see older ones, click the pin to keep it through the cap and through clearing, and swipe it sideways to remove it. The trash at the top clears everything that is not pinned. If something is running in the activity pill, it rides at the far right of the clipboard pill as a bump: click it to expand that activity instead. The pill folds once you pick an entry, press `SUPER + V` again, or leave it with the pointer. It is pointer only: search over the whole history waits for a keyboard owner.

- `qs -p ~/.config/vados/shell ipc call activity toggle` (or the Hyprland global shortcut `vados:activity`) expands or folds the pill, `... activity close` folds it, `... activity pin <recording|call|media|notifications|tray>` picks what it shows, `... activity current` names it.
- `... ipc call overlay toggle <search|settings|dashboard|notifications|screenshot>`, `... overlay close` (closes the topmost), `... overlay top`.
- `... ipc call attention quiet true` (do not disturb), `... attention toggle`, `status`, `dismiss` (hides the current pop-up).
- `... ipc call clipboard toggle` (`SUPER + V`, Hyprland `vados:clipboard`) opens or closes the clipboard history, `... clipboard close` closes it, `... clipboard clear` empties it (pinned entries stay), `... clipboard count` reports how many entries are kept.
- `... ipc call notifications enable` makes the shell your notification daemon, `... disable` gives it back; `toggle` (`SUPER + N`, Hyprland `vados:notifications`) opens or closes the notifications menu and `close` closes it; `status`, `count` and `clear` report and dismiss (`clear` also empties the history).

## Network

The shell reaches the network only from these files, and only while the feature that needs it is on screen:

| File | Host | When |
|---|---|---|
| `services/Weather.qml` | api.open-meteo.com, geocoding-api.open-meteo.com; ipinfo.io when `weather.location` is empty | while the dashboard is open, at most every 15 minutes; after a failed request it retries after 1 s, doubling up to 1 minute |
| `services/Traffic.qml` | `ping` to 1.1.1.1 | while the dashboard is open |
| `services/Transfer.qml` | none itself; it starts `blip`, which sends the chosen files to your device through Blip's servers | only when you press SEND in the notifications menu and pick files |

Nothing else talks to the network. `tools/check-rules.py` fails when another file does.

## Layout

```
shell/
├── shell.qml     entry point
├── config/       Config, Appearance (V/AS tokens), Motion
├── state/        shared UI state (the only sideways channel)
├── services/     data singletons, no UI (Compositor is the WM boundary)
├── components/   V/AS primitives
├── modules/      features; never import each other
├── windows/      layer-shell hosts per screen
├── keybinds/     shortcuts + IPC, only change state
├── scripts/      helpers services run (the portal file chooser, the clipboard reader)
└── utils/
shell.json        user config
```

## Settings (`shell.json`)

| Key | Values | Default |
|---|---|---|
| `taskbar.enabled` | `true` / `false` | `true` |
| `taskbar.style` | `"floating"`: liquid bubbles beside the edge<br>`"fused"`: tabs grown out of the screen edge<br>`"bare"`: no container, icons only | `"floating"` |
| `taskbar.side` | `"left"` / `"right"` | `"left"` |
| `taskbar.compact` | `true`: idle pills folded to power, audio and a dot (drag down on them)<br>`false`: all idle pills (drag up, or press the dot) | `false` |
| `taskbar.gather` | how the taskbar leaves when an overlay opens (Settings > Settings, a trial toggle)<br>`"merge"`: the pills stream into one circle at the taskbar column, which bursts into the overlay<br>`"shrink"`: each pill turns into a circle and shrinks away in place while the overlay's circle grows and bursts at once; on close the overlay shrinks into the edge and the pills pop back in where they sit, nothing streams | `"merge"` |
| `appearance.accent` | hex colour, e.g. `"#ffffff"`; set live from the settings window (User tab) | `"#ffffff"` |
| `desktop.mode` | `"canvas"` / `"desktop"` (driftwm only) | `"canvas"` |
| `search.favorites` | desktop entry ids, e.g. `["firefox.desktop"]`; they lead the search list while the field is empty | `[]` |
| `search.hidden` | desktop entry ids the search leaves out unless HIDDEN is on | `[]` |
| `profile.name` | your name; its initial shows in the search circle when there is no picture | `""` |
| `profile.secondName` | optional second name | `""` |
| `profile.github` | your GitHub username | `""` |
| `pills.opacity` | 0 to 1, how opaque pills and overlay bodies are (settings, Customization / Pills) | `0.94` |
| `pills.blur` | 0 to 1, scales the liquid blur of every pill and overlay (settings, Customization / Pills) | `1` |
| `lock.layout` | lock screen modules as `"module:column:row"` on the 16 x 16 grid (modules `clock`, `profile`, `login` are required; `weather`, `music`, `dashboard`, `notifications` optional); edited in settings, Customization / Lock Screen | `["clock:5:1", "profile:6:4", "login:5:8"]` |
| `lock.wallpaper` | image path of the lock screen background | `""` |
| `pills.color` | hex colour of every pill and overlay body; `""` is the default dark | `""` |
| `services.mediaPlayer` | `true`: the media player appears in the activity pill when something plays (settings, Advanced)<br>`false`: it never does | `true` |
| `profile.picture` | your profile picture (chosen by clicking the avatar in settings), shown in the search's profile blob | `""` |
| `weather.location` | city for the dashboard weather, e.g. `"Berlin"`; `""` guesses from your IP | `""` |
| `dashboard.taskIcons` | `true`: task manager rows are taller and show each program's icon before its name (also the grid button beside NAME in the task manager)<br>`false`: names only | `false` |
| `motion.reduced` | `true`: transitions are instant and idle bubbles and splashes stop; typed text and drags stay (also in settings, Settings tab)<br>`false`: full motion | `false` |
| `motion.burst` | `"static"`: every overlay bursts open with the same wave<br>`"procedural"`: each burst rolls its own wave (crest heights, lengths, jet, splashes) and shoots a random handful of small blobs from random points on the body's outline that fall back into it (also in settings, Settings tab, BURST) | `"static"` |
| `attention.doNotDisturb` | `true`: only critical notifications may pop up; the rest wait in the activity bar (also in settings, Settings tab)<br>`false`: notifications may pop up unless a window is fullscreen | `false` |
| `notifications.enabled` | `true`: the shell becomes the notification daemon (replaces mako, dunst, swaync) and shows notifications as alerts out of the activity pill<br>`false`: your existing daemon keeps them | `false` |
| `notifications.history` | how many notifications the notification menu keeps, 0 to 1000; the oldest go first. The history is saved in `~/.cache/vados/notifications.json` (message text included); clearing the menu empties it | `200` |
| `send.app` | the app the notification menu sends files with; `"blip"` ([Blip](https://blip.net)) is the only one so far | `"blip"` |
| `send.devices` | the devices shown in the notification menu, as `"name:peer"`, e.g. `["Phone:vadim-pixel"]`; the peer is the device as Blip knows it (`blip --peer=<peer>`). With none, SEND hands the file to Blip's own window | `[]` |
| `clipboard.enabled` | `true`: the shell keeps a clipboard history and `SUPER + V` opens it out of the activity pill (needs `wl-clipboard` and `python3`; it reads everything you copy)<br>`false`: nothing is watched or kept | `true` |
| `clipboard.size` | how many clipboard entries are kept, 0 to 1000; the oldest unpinned go first. Saved in `~/.cache/vados/clipboard.json` (text included, detected secrets never) | `150` |
| `clipboard.images` | `true`: copied images are kept too, as files in `~/.cache/vados/clipboard/`<br>`false`: copied images are not kept, and turning it off deletes the kept ones | `true` |
| `capture.screenshots` | folder screenshots are saved in (settings, Settings tab); `~` is your home. `""` is `$XDG_PICTURES_DIR/Screenshots`, else `~/Pictures/Screenshots` | `""` |
| `capture.recordings` | folder screen recordings are saved in (settings, Settings tab); `~` is your home. `""` is `$XDG_VIDEOS_DIR/Recordings`, else `~/Videos/Recordings` | `""` |
| `rendering.quality` | `"full"`: every liquid effect<br>`"lite"`: cheaper rendering for weaker GPUs | `"full"` |

Changes apply live. The file carries a `version` (currently `1`) so later releases can migrate it; a file without one is read as the old layout and gets the version added. A value with the wrong type or outside the values above falls back to its default, and the shell says so in its log (lines starting `vados: config:`), naming the key, what it found and what it expected. Repaired values are written back to the file; unknown keys are reported and ignored. A file that is not valid JSON is left untouched and the shell keeps its current settings until you fix it.

## Development

- `python tools/check-rules.py` checks the hard rules (also a Claude Code Stop hook).
- `python tools/tests/run.py` runs the Qt Quick tests (needs PySide6): the liquid engine, overlays, gestures, attention, the burst, persistence and Desktop-mode recovery, logging, supervision and diagnostics, and a check that the whole preview loads without a warning.
- `python tools/preview/play.py` opens the playground (Windows paths; see `.claude/CLAUDE.md`).

### Frame by frame

Press `KP_0` (numpad 0): every animation freezes where it is and the top right shows `FRAME n` with the names of the animations playing (`dashboard burst entering`, `task pill leave`, `x3` when several run at once, `NO ANIMATION` when none). Trigger the animation you want to look at (open the dashboard, hover a pill): it starts frozen at frame 0. Then:

- `UP` (or `RIGHT`) runs exactly one frame (about 1/60 s) and freezes again;
- `DOWN` (or `LEFT`) goes back one frame. Every frame you stepped is kept as a picture (the last 120, at half resolution), and the HUD says `REPLAY` while you look at one; going forward again through the pictures runs nothing, and from the newest frame `UP` runs a real frame again;
- `KP_ADD` (numpad +) copies a screenshot of the shell to the clipboard with `wl-copy` (install `wl-clipboard`), also when nothing is held: the shell windows on a dark ground, at full resolution, or the frame you are replaying;
- `ESC` or `KP_0` again lets everything run and forgets the pictures.

Give the frame and the name (`frame 14, dashboard burst entering, the wall ...`) and the exact moment is known. `qs -p ~/.config/vados/shell ipc call frames step`, `... frames back`, `... frames shot` and `... frames status` do the same without the keyboard. While held, the shell holds the keyboard on the screen where you pressed the key (mouse and compositor shortcuts still work). Timers that sequence motion (the taskbar stagger timers) and `Behavior` fades (the dashboard dim, bar fills, hover colours) keep running while held. With Num Lock off the numpad sends `KP_Insert` and `KP_Add` keeps its name. The screenshot holds only what the shell draws, not the windows of other applications.

### Logs and diagnostics

Every line the shell logs starts with `vados: <subsystem>:` (`compositor`, `network`, `removable`, `traffic`, `weather`, `lifecycle`, `config`), says what failed and what the shell does about it, and is printed once per 5 minutes at most, with a repeat count. Read them where the shell runs:

- started from a terminal: the `qs -p ~/.config/vados/shell` output;
- started by the compositor or a systemd user unit: `journalctl --user -b | grep 'vados:'` (add `-f` to follow).

Background processes (the driftwm event stream, `nmcli monitor`, `udevadm monitor`, `ping` and the weather requests while the dashboard is open) restart on their own after a failure, waiting 1 s, then 2, 4 ... up to a minute, and log the failure and the recovery.

`qs -p ~/.config/vados/shell ipc call diagnostics report` prints the state of the running shell: the compositor and its support level, which capabilities are missing, open overlays and their phases, each restarted background process with its restart count and last failure, and the last 100 log entries. Attach it to bug reports.

Agent-facing docs (architecture, decisions, quirks, roadmap) live in [.claude/](.claude/CLAUDE.md).
