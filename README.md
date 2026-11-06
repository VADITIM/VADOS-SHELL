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
"ctrl+right" = "exec qs -p ~/.config/vados/shell ipc call activity next"
"ctrl+left" = "exec qs -p ~/.config/vados/shell ipc call activity previous"
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
bind = CTRL, right, global, vados:activityNext
bind = CTRL, left, global, vados:activityPrevious
```

### Anything else

Bind keys to `qs -p ~/.config/vados/shell ipc call search toggle`, `... settings toggle` and `... dashboard toggle`. The taskbar hides only when the focused window is fullscreen or maximized, because plain Wayland gives no window geometry.

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

## Activity pill

A liquid pill in the middle of the taskbar shows what is running now. It has four states:

- **Hidden**: gone.
- **Idle**: a small bead, nothing happening.
- **Active**: a capsule with the leading activity (Spotify or any MPRIS player with live bars, a Discord voice call with the mic state). Other running activities hang under it as small droplets; scroll on the pill to bring the next one to the front.
- **Expanded**: the pill spreads from the taskbar towards the screen into that activity's own shape. Music: a disc with the cover and a progress ring, title, artist, previous / play / next. Discord: the call time, with mic and deafen droplets hanging under it.

`CTRL + RIGHT` steps up (hidden, idle, active, expanded), `CTRL + LEFT` steps down; a click on the pill steps up too, and a click on the expanded body folds it back. It turns active on its own when something starts and idle when everything stops. IPC: `ipc call activity next`, `previous`, `mode <name>`, `rotate`.

`CTRL + LEFT` / `RIGHT` are global bindings, so they shadow word-jump inside apps. Rebind them in the compositor config if that matters to you. Discord's mic and deafen mute Discord's own PipeWire streams, so Discord's interface does not show them.

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

Changes apply live.

Agent-facing docs (architecture, decisions, quirks, roadmap) live in [.claude/](.claude/CLAUDE.md).
