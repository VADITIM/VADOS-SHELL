# VAD/OS Shell

A desktop environment for Wayland, written in [Quickshell](https://quickshell.org) (Qt 6 / QML) on V/AS (VAD/OS APPLICATION SYSTEMS). It is more than a rice: taskbar, search, dashboard, settings and window management are one liquid system, not separate widgets. Everything grows out of the taskbar edge, fuses with its neighbours and flows back into it.

It targets [driftwm](https://github.com/malbiruk/driftwm) first and stays usable on Hyprland and on any wlroots-style compositor.

- **Taskbar** on the left or right edge in three styles, with foldable idle pills (power, audio, battery, network, USB, tray, clock).
- **Search** as a full-height liquid column: fuzzy app search, favourites, best match.
- **Dashboard** with CPU, GPU, RAM, disk, battery and a seven-day weather forecast.
- **Settings** that open from the taskbar: accent colour, taskbar style and side, window mode.
- **Window modes** on driftwm: free infinite canvas, or a Windows-style desktop with snap, maximize and minimize.
- **Live config** in one `shell.json`.

## Install

Clone into `~/.config/vados` and start the shell with `qs -p ~/.config/vados/shell`.

### driftwm (primary)

`~/.config/driftwm/config.toml`:

```toml
autostart = ["qs -p ~/.config/vados/shell"]

[keybindings]
"super+g" = "exec qs -p ~/.config/vados/shell ipc call search toggle"
"ctrl+p" = "exec qs -p ~/.config/vados/shell ipc call settings toggle"
"super+a" = "exec qs -p ~/.config/vados/shell ipc call dashboard toggle"
"super+d" = "exec qs -p ~/.config/vados/shell ipc call desktop toggle"
"super+up" = "exec qs -p ~/.config/vados/shell ipc call desktop maximize"
"super+down" = "exec qs -p ~/.config/vados/shell ipc call desktop minimize"
"super+left" = "exec qs -p ~/.config/vados/shell ipc call desktop snap left"
"super+right" = "exec qs -p ~/.config/vados/shell ipc call desktop snap right"
"f11" = "exec qs -p ~/.config/vados/shell ipc call desktop fullscreen"
```

Check the keybinding table name against your driftwm version's `config.reference.toml`.

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
```

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

`SUPER + G` opens the app search: the taskbar streams into a circle at the edge, which bursts into a full-height liquid column. Results run down its left side, favourites sit in a lobe off the top, the best match swells out of the middle of the wall, and the field is at the bottom. Type to fuzzy search. Arrows and Tab move, Enter opens, Esc clears and then closes, and right click pins an app to favourites.

## Taskbar

Drag down on the idle pills to fold them to power, audio and a small dot; drag up, or press the dot, to unfold them.

## Settings window

The gear above power or `CTRL + P` opens the settings. The whole taskbar melts into the gear, which shoots from there into the screen centre and pops open into the settings panel, with bubbles rising off it. A tab bar buds out of its left edge: Appearance, Taskbar, and Desktop on driftwm. Up/Down or Tab switch tabs. Esc, `CTRL + P` or a click outside closes it: the panel implodes, flies back, and the taskbar pops back in.

`CTRL + P` is a global binding, so it shadows Ctrl+P (print) inside apps. Rebind it in the compositor config if that matters to you.

## Dashboard

A click on the taskbar clock (or `SUPER + A`, or `ipc call dashboard toggle`) streams the taskbar into a new circle at the taskbar's position, fused to the screen edge, which bounces out along the dashboard with waves crashing onto its walls, with bubbles rising off it. It shows:

- CPU and GPU: temperature as the ring around the chip, load as the percentage inside it (the chip turns the load's colour). The GPU's curved line at its top left is VRAM.
- RAM: a chip ring tracking used memory, with used/total GB under it.
- Disk: in the notch at the bottom, fill bar and used/total GB. Tap the disk icon to page through disks.
- Battery (laptops only): a vertical battery in a notch on the far side, filled and coloured in six steps by charge (red under 10%, then orange, yellow, lime, green, blue above 80%), a bolt while charging.
- Weather now and for the next six days, from [Open-Meteo](https://open-meteo.com). Set a city with `qs -p ~/.config/vados/shell ipc call dashboard location "Berlin"`; empty guesses the location from your IP (ipinfo.io).

Bars and rings are colour-coded in bands: blue, yellow, orange, red. GPU readings need `nvidia-smi` (NVIDIA) or the amdgpu driver (AMD). Esc or a click outside closes it.

## Activity and notifications

The activity bar (coming) will show what is happening now inside the taskbar. Its state and the notification service exist already:

- `qs -p ~/.config/vados/shell ipc call activity toggle` (or the Hyprland global shortcut `vados:activity`), `... activity current`, `... activity pin notifications`.
- `... ipc call overlay toggle <search|settings|dashboard>`, `... overlay close` (closes the topmost), `... overlay top`.
- `... ipc call attention quiet true` (do not disturb), `... attention toggle`, `status`, `dismiss` (hides the current pop-up).
- `... ipc call notifications enable` makes the shell your notification daemon, `... disable` gives it back; `status`, `count` and `clear` report and dismiss.

## Network

The shell reaches the network only from these files, and only while the feature that needs it is on screen:

| File | Host | When |
|---|---|---|
| `services/Weather.qml` | api.open-meteo.com, geocoding-api.open-meteo.com; ipinfo.io when `weather.location` is empty | while the dashboard is open, at most every 15 minutes; after a failed request it retries after 1 s, doubling up to 1 minute |
| `services/Traffic.qml` | `ping` to 1.1.1.1 | while the dashboard is open |

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
| `appearance.accent` | hex colour, e.g. `"#ffffff"`; set live from the settings window (Appearance tab) | `"#ffffff"` |
| `desktop.mode` | `"canvas"` / `"desktop"` (driftwm only) | `"canvas"` |
| `search.favorites` | desktop entry ids, e.g. `["firefox.desktop"]` | `[]` |
| `profile.name` | your name; its initial shows in the search circle when there is no picture | `""` |
| `profile.picture` | path to your profile picture, shown in the search circle until you type | `""` |
| `weather.location` | city for the dashboard weather, e.g. `"Berlin"`; `""` guesses from your IP | `""` |
| `motion.reduced` | `true`: transitions are instant and idle bubbles and splashes stop; typed text and drags stay (also in settings, System tab)<br>`false`: full motion | `false` |
| `attention.doNotDisturb` | `true`: only critical notifications may pop up; the rest wait in the activity bar (also in settings, System tab)<br>`false`: notifications may pop up unless a window is fullscreen | `false` |
| `notifications.enabled` | `true`: the shell becomes the notification daemon (replaces mako, dunst, swaync); nothing shows them yet, so leave it off until the activity bar lands<br>`false`: your existing daemon keeps them | `false` |
| `rendering.quality` | `"full"`: every liquid effect<br>`"lite"`: cheaper rendering for weaker GPUs | `"full"` |

Changes apply live. The file carries a `version` (currently `1`) so later releases can migrate it; a file without one is read as the old layout and gets the version added. A value with the wrong type or outside the values above falls back to its default, and the shell says so in its log (lines starting `vados: config:`), naming the key, what it found and what it expected. Repaired values are written back to the file; unknown keys are reported and ignored. A file that is not valid JSON is left untouched and the shell keeps its current settings until you fix it.

## Development

- `python tools/check-rules.py` checks the hard rules (also a Claude Code Stop hook).
- `python tools/tests/run.py` runs the Qt Quick tests (needs PySide6): the liquid engine, overlays, gestures, attention, the burst, persistence and Desktop-mode recovery, logging, supervision and diagnostics, and a check that the whole preview loads without a warning.
- `python tools/preview/play.py` opens the playground (Windows paths; see `.claude/CLAUDE.md`).

### Logs and diagnostics

Every line the shell logs starts with `vados: <subsystem>:` (`compositor`, `network`, `removable`, `traffic`, `weather`, `lifecycle`, `config`), says what failed and what the shell does about it, and is printed once per 5 minutes at most, with a repeat count. Read them where the shell runs:

- started from a terminal: the `qs -p ~/.config/vados/shell` output;
- started by the compositor or a systemd user unit: `journalctl --user -b | grep 'vados:'` (add `-f` to follow).

Background processes (the driftwm event stream, `nmcli monitor`, `udevadm monitor`, `ping` and the weather requests while the dashboard is open) restart on their own after a failure, waiting 1 s, then 2, 4 ... up to a minute, and log the failure and the recovery.

`qs -p ~/.config/vados/shell ipc call diagnostics report` prints the state of the running shell: the compositor and its support level, which capabilities are missing, open overlays and their phases, each restarted background process with its restart count and last failure, and the last 100 log entries. Attach it to bug reports.

Agent-facing docs (architecture, decisions, quirks, roadmap) live in [.claude/](.claude/CLAUDE.md).
