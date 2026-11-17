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
"mod+p" = "spawn qs -p ~/.config/vados/shell ipc call settings toggle"
"super+d" = "spawn qs -p ~/.config/vados/shell ipc call dashboard toggle"
"super+n" = "spawn qs -p ~/.config/vados/shell ipc call notifications toggle"
"super+v" = "spawn qs -p ~/.config/vados/shell ipc call clipboard toggle"
"super+l" = "spawn qs -p ~/.config/vados/shell ipc call lock lock"
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
source = ~/.config/hypr/vados-displays.conf
```

The `source` line loads the monitor layout kept in the Displays tab (settings, SETTINGS / DISPLAYS); the shell writes that file only when you press KEEP. Hyprland warns about a missing file until you keep a layout once.

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
| `sessionLock` | yes | yes | no | No lock screen (ext-session-lock): the lock button and `ipc call lock lock` hand the request to `loginctl lock-session`, so a locker of your own (swaylock) can take it. |
| `displayPower` | yes | yes | no | The locked screen turns black after `lock.blankAfter` instead of switching the displays off. |
| `ownBackground` | yes | no | no | The shell draws the wallpaper itself on the background layer, with the widgets on it. With it the compositor draws the wallpaper, and the widgets sit on the bottom layer above it. |
| `outputConfiguration` | yes | yes | no | No Displays tab: the SETTINGS tab has no second bar, and monitors are arranged with the compositor's own tools. driftwm reads the monitors through wlr-output-management (`scripts/outputs.py`) and takes the layout as `[[outputs]]` in its `config.toml`, which it reloads live; Hyprland reads `hyprctl -j monitors all` and applies `hyprctl keyword monitor` rules. |

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

`SUPER + G` opens the app search: the taskbar streams into a circle at the edge, which bursts into a full-height liquid column. Results run down its left side from the top, the best match swells out of the middle of the wall, and the field is at the bottom. Near the top a droplet shoots out of the wall and bursts into your profile: your picture in a liquid blob, your name below it (click either to edit your profile in settings) and the power options (lock, suspend, restart, shut down; restart and shut down ask twice) stacked close on its left. The best match is tinted with its app's own colour. Type to fuzzy search. Arrows and Tab move, Enter opens, Esc clears and then closes. Right click (or the Menu key) opens a small menu to favourite an app (favourites lead the list while the field is empty) or hide it; the grey HIDDEN at the very bottom (or Ctrl+H) shows hidden apps again. Next to it a NEW tab appears (or Ctrl+N) while apps installed in the last two weeks are still unopened from the launcher; it lists only those, newest first.

## Taskbar

Drag down on the idle pills to fold them to power, audio and a small dot; drag up, or press the dot, to unfold them.

Click the Wi-Fi pill's icon to grow it into the network page. Tap a network to join it: a known or open network connects at once, a secured one asks for its password in the pill (SHOW reveals it, Enter joins, Escape cancels), and a refused password asks again under WRONG PASSWORD. Networks with a sign-in (802.1X, WPA-Enterprise) ask for a user name and password; a refused sign-in asks again with the user name kept. iwd only joins such a network from a provisioning file in `/var/lib/iwd` (root only), so on iwd the shell writes `<network>.8021x` (PEAP with MSCHAPv2, user name and password, readable by root only) through `pkexec`, which needs a running polkit agent (polkit-gnome, polkit-kde-agent or similar, started by the compositor); without one the page says NO POLKIT AGENT RUNNING. On NetworkManager it adds a PEAP connection with the user name and passes the password through `nmcli --ask`. OTHER joins a hidden network by name. Right-click a known network for FORGET. While a field is shown the taskbar holds the keyboard; it lets go when the field closes. On iwd the password goes to iwd through a D-Bus agent (`scripts/wifi.py`, `python-gobject`); on NetworkManager through `nmcli --ask`; it is never on a command line or in the shell's own files (an 802.1X sign-in on iwd is stored by iwd's own provisioning file, like iwd stores every Wi-Fi password).

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

The gear above power or `CTRL + P` opens the settings: the taskbar melts into a circle that sweeps across the whole screen as a liquid burst, bounces on the far edge and settles into a body merged with the screen edges. The taskbar becomes the main navigation inside it, a tall accent-coloured pop bar with User, Settings, Customization and Advanced; tabs with deeper levels open a quieter, translucent second pop bar to its right (Settings: General, Displays, where the compositor supports it; Customization: Wallpaper, Lock Screen, Widgets, Pills, Taskbar, System Font; Advanced: Link to VAD/OS, Services). Hovering an entry of either bar pops its name out beside it, and the page says where you are in a heading (`CUSTOMIZATION / PILLS`). Every page groups its settings into flat titled sections divided by thin lines and set in columns; each setting is a small label over its choices (`FULL | REDUCED`), the chosen one ringed or filled. On the Settings tab a colour wheel on the right sets that mark: OUTLINE or PILL, each with its own colour (FOLLOW THE ACCENT clears it). The taskbar's clock stays in the bottom-left corner. Wallpaper shows the current wallpaper large with the earlier images of your wallpaper folder stacked above it and the later ones below; scroll, drag, PageUp/PageDown or click a card to move through them, and the one in the middle becomes the wallpaper of every screen a moment after you stop (NONE, the first entry, hands the background back to the compositor). Lock Screen shows the 16 x 16 grid over the lock wallpaper, with the modules to place beyond the edge of the body. Widgets shows the monitor you pick (MONITOR) with its wallpaper and grid; switch a widget ON to place it in the first free spot, OFF to take it away, and drag it to move it. System Font lists the installed font families, previews the one you pick and, on APPLY, makes it the font of every app (a fontconfig alias in `~/.config/fontconfig/conf.d/99-vados-system-font.conf` and GTK's `font-name`); it takes that role only when you apply, and RESTORE removes the alias and puts GTK's previous font back. Displays arranges the monitors without an external tool: each monitor is a body on a canvas, sized by its resolution, scale and rotation; drag one and it docks against the nearest edge of another (monitors may not overlap and every one has to touch another along an edge), tap or pick one under MONITOR to change its resolution (the arrows), refresh rate, scale and rotation, or set OUTPUT to OFF to take it out of the layout as if unplugged (one monitor always stays on; driftwm needs the local `disable-outputs.patch` build for this, it writes `enabled = false` into that monitor's entry). APPLY (or Enter) tries the layout at once and starts a 15 second countdown: KEEP (or Enter again) keeps it, REVERT or the end of the countdown puts the previous layout back, so a mode that leaves the screen black undoes itself. On driftwm the layout is written as `[[outputs]]` entries in `~/.config/driftwm/config.toml` (only `scale`, `transform`, `position` and `mode` of the listed monitors change; other keys and hot corners stay) and driftwm applies it live; a shell restart during the countdown resumes it, or reverts at once when it ran out. On Hyprland it is applied with `hyprctl keyword monitor` and written to `~/.config/hypr/vados-displays.conf` once kept. Link to VAD/OS shows the family apps (Files, Gallery, Notes, Terminal): an installed one can become the default for its file types (`xdg-mime`, after a second press on CONFIRM), a missing one opens its GitHub releases page in your browser. Up/Down/Tab switch tabs, Left/Right the second bar. Esc, `CTRL + P` or a click outside closes it: the body collapses back into the taskbar.

`CTRL + P` is a global binding, so it shadows Ctrl+P (print) inside apps. Rebind it in the compositor config if that matters to you.

## Battery charge limit (Acer)

On Acer laptops the Settings tab shows a BATTERY section: CHARGE LIMIT `80%` stops charging at 80% (Acer's Battery Health Mode), `full` charges to 100% (`battery.limit`). Anywhere else, or without the driver, the section is not there and the key does nothing. It needs the `acer-wmi-battery` driver (AUR `acer-wmi-battery-dkms-git`), loaded at boot:

```
echo acer_wmi_battery | sudo tee /etc/modules-load.d/acer-wmi-battery.conf
```

and permission for your user to write the switch, in `/etc/tmpfiles.d/vados-battery.conf`:

```
z /sys/bus/wmi/drivers/acer-wmi-battery/health_mode 0664 root wheel -
z /sys/class/power_supply/BAT*/charge_control_end_threshold 0664 root wheel -
```

The shell applies the setting when it starts and whenever you change it; without write access it logs `vados: battery:` and leaves the firmware as it is.

## Desktop widgets

Widgets sit on the desktop of each monitor, above the wallpaper and below every app window, and they are never hidden with the taskbar. On driftwm they are fixed to the monitor, not to the canvas, so panning or zooming the canvas never moves them. There are seven: the dashboard's readings as small panels and a note: **Clock** (time and date), **System** (CPU, GPU and RAM rings, coloured by load), **Weather** (now and three days, from Open-Meteo), **Network** (download and upload with a graph of the last minute), **Battery** (charge, coloured like the dashboard's) **Disk** (the first disk, used of total) and **Notes** (a sticky note, like Windows Sticky Notes). Each pops in on its own.

**Notes**: click the note and type; the border turns accent while you write, Escape or a click anywhere else stops. The text is saved as you type to `~/.cache/vados/notes.json` and is the same note on every monitor, so do not keep passwords in it. Long notes scroll with the wheel. While the pointer is over the note, the desktop layer asks the compositor for the keyboard on demand (only then), so a click there gives it focus; dragging the note still moves it.

## Calculator

Type **calculator** in the search and press Enter (or `qs -p ~/.config/vados/shell ipc call calculator open | close | toggle`) to open a small calculator in its own app window, placed, moved and closed by the compositor like any other window. Keys pop in from the middle out. Type with the keyboard (digits, `+ - * /`, `x`, `%`, parentheses, `.` or `,`) or click the keys; Enter or `=` gives the result, Backspace deletes, Escape or Delete clears. While you type, the line above shows the result so far; after `=` it shows what was calculated, and an operator continues from the result while a digit starts over. Open parentheses close themselves, and dividing by zero says so instead of answering. It runs inside the shell, so restarting or reloading the shell closes it.

Place them in Settings, Customization / Widgets, per monitor, or drag a widget on the desktop: it follows the pointer and snaps to the nearest free cell of an 88 px grid when you let go. Each monitor keeps its own layout in `widgets.layout`, by monitor name: unplug one and plug it back and its widgets return; a new monitor starts empty; a changed resolution or scale moves widgets that no longer fit to the nearest free spot (the saved layout stays as it was until you move one). While a fullscreen window covers a monitor its widgets stop updating, and the CPU, disk and weather readings are polled only while a widget that shows them is on an uncovered screen. Nothing on the desktop moves on its own: a widget changes only when its reading does (once a second at most), and under reduced motion even that and the pop-in are instant.

## Dashboard

A click on the taskbar clock (or `SUPER + A`, or `ipc call dashboard toggle`) streams the taskbar into a new circle at the taskbar's position, fused to the screen edge, which bounces out along the dashboard with waves crashing onto its walls, with bubbles rising off it. It shows:

- CPU and GPU: temperature as the ring around the chip, load as the percentage inside it (the chip turns the load's colour). The GPU's curved line at its top left is VRAM.
- RAM: a chip ring tracking used memory, with used/total GB under it.
- Disk: in the notch at the bottom, fill bar and used/total GB. Tap the disk icon to page through disks.
- Battery (laptops only): a vertical battery in a notch on the far side, filled and coloured by charge (red under 10%, orange under 20%, yellow under 40%, lime under 60%, green above), green with a bolt while charging.
- Task manager: once the dashboard has opened, a pill grows out of its far side, runs to the far screen edge and fuses with it as a tall column. Two tabs: **Processes** (every running program, grouped by name, with CPU, memory, disk and network; the column headers show the totals) and **App history** (CPU time, peak memory and disk I/O per program, kept across restarts in `~/.cache/vados/apphistory.json`). Click a column header to sort by it, again to flip the order. Right-click a row for **Kill** (SIGTERM to every process of the row), **Open** (focuses its window, or starts it) and **Find path** (shows the program in your file manager). The search pill above the column filters both tabs by program name or path; start typing anywhere in the task manager to search, Escape clears it. Keyboard: up and down select, left, right or Tab switch tabs, Menu or Shift+F10 opens the row menu, Enter opens, Delete kills. Disk needs read access to `/proc/<pid>/io`, so it shows `--` for other users' processes; per-program network is not measured yet (`--`). It needs `python3`; Find path uses `gdbus` (`org.freedesktop.FileManager1`) and falls back to `xdg-open` on the folder. The grid button beside NAME shows each program's icon in taller rows (`dashboard.taskIcons`). Hidden when the screen is too narrow for it.
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

On by default (`clipboard.enabled`), `SUPER + V` grows the activity pill into a bigger pill beside the taskbar with your recent copies, pinned ones first; images show large, three rows tall. Text, links, files and images each look different; a copy that looks like a key, token or password is shown as dots and is never written to disk, and a copy a password manager marks as secret (KeePassXC and others that set `x-kde-passwordManagerHint`) is never kept at all. Click an entry to copy it again (it moves to the top, no duplicate), scroll to see older ones, click the pin to keep it through the cap and through clearing, and swipe it sideways to remove it. The trash at the top right clears everything that is not pinned; the number of entries sits beside it. While open, the pill eats the taskbar pills it would overlap and gives them back once it has folded. The pill folds once you pick an entry, press `SUPER + V` again, or leave it with the pointer. It is pointer only: search over the whole history waits for a keyboard owner.

- `qs -p ~/.config/vados/shell ipc call activity toggle` (or the Hyprland global shortcut `vados:activity`) expands or folds the pill, `... activity close` folds it, `... activity pin <recording|call|media|notifications|tray>` picks what it shows, `... activity current` names it.
- `... ipc call overlay toggle <search|settings|dashboard|notifications|screenshot>`, `... overlay close` (closes the topmost), `... overlay top`.
- `... ipc call attention quiet true` (do not disturb), `... attention toggle`, `status`, `dismiss` (hides the current pop-up).
- `... ipc call lock lock` (`SUPER + L`, Hyprland `vados:lock`) locks the session, `... lock status` says `unlocked`, `locking`, `locked`, `blank` or `unsupported`. There is no IPC unlock: only your password opens it.
- `... ipc call clipboard toggle` (`SUPER + V`, Hyprland `vados:clipboard`) opens or closes the clipboard history, `... clipboard close` closes it, `... clipboard clear` empties it (pinned entries stay), `... clipboard count` reports how many entries are kept.
- `... ipc call notifications enable` makes the shell your notification daemon, `... disable` gives it back; `toggle` (`SUPER + N`, Hyprland `vados:notifications`) opens or closes the notifications menu and `close` closes it; `status`, `count` and `clear` report and dismiss (`clear` also empties the history).

## Lock screen

Lock from the power pill's lock button, the lock button beside the search's profile, `SUPER + L` (driftwm bind above; Hyprland `vados:lock`) or `qs -p ~/.config/vados/shell ipc call lock lock`. The taskbar gathers at its power pill, slings to the middle of the screen and bursts into the lock screen's modules over your lock background (`lock.wallpaper`, else the desktop wallpaper), heavily blurred. Type your login password anywhere and press Enter; Backspace deletes, Escape clears. Unlocking happens the moment PAM accepts the password; then the modules flow back into the taskbar, which bursts out along the edge and returns.

- **Security**: the lock is the compositor's session lock (ext-session-lock), not a window over the desktop, so nothing behind it is reachable. If the shell crashes while locked the session stays locked; restarting the shell in the same login locks it again and shows the password field. While locked, the shell stops reloading on file changes (a reload would end the lock). Passwords are checked by PAM with the `login` service (`/etc/pam.d/login`) and never stored or logged; a wrong password, too many attempts or a PAM error is shown on the screen and logged (`vados: lock: ...`).
- **Modules**: place them in Customization / Lock Screen on the 16 x 16 grid (`lock.layout`). Time and date, your profile and the login window are always there; weather, music player, mini dashboard and notifications are optional. The notifications module shows only app names and counts, never message text. While a call, music, a recording or unread notifications are live, a small pill sits above your picture.
- **Several screens**: every screen is locked; the modules sit on the screen that had focus, the others show the background. Unplugging that screen moves them to another one.
- **Screen off**: after `lock.blankAfter` seconds without input on the locked screen (default 60, `0` never, set under Customization / Lock Screen) the displays switch off (`wlopm` on driftwm, `hyprctl dispatch dpms` on Hyprland) and wake to the lock on the next key or move. The unlocked desktop never blanks, and the shell never locks by itself.
- **Compositors**: driftwm and Hyprland (`sessionLock` in the compositor table). On Hyprland a locker that crashed can only be replaced with `misc:allow_session_lock_restore = true`. Elsewhere the lock button hands the request to `loginctl lock-session` for a locker of your own.
- **If the lock cannot check your password** (a broken PAM setup): switch to a text console (`CTRL + ALT + F3`), log in, and end the graphical session with `loginctl terminate-session <id>` (`loginctl list-sessions` shows it), or remove `~/.cache/vados/lock.json` before restarting the shell so it does not lock again.

## Login screen (SDDM)

An SDDM theme in `sddm/vados` that matches the shell: the clock and date, your profile picture in an accent ring with your name (arrows switch users when there are several), the password pill, SUSPEND, RESTART and SHUT DOWN on the left (restart and shut down ask SURE? first), and the session below (click it, or Left and Right on it). Everything drops in one after another: the clock rolls its digits, the profile lands with a splash ring, the password pill spreads out of a circle, and faint bubbles rise in your accent. Typing pops a dot in for each character. A wrong password turns the dots red, drops them out of the pill, shakes it and says so in red; CAPS LOCK is shown while it is on. PREVIOUS at the top right switches every screen to SDDM's built-in login screen for this login only; the next start shows VAD/OS again. Tab moves between the pieces, Enter or Space presses them. SDDM keeps its own PAM stack, so the keyring still unlocks at login.

- `python sddm/install.py --preview` shows it in SDDM's test mode with your `shell.json` applied; nothing system-wide changes.
- `python sddm/install.py` stages the theme with your accent, `lock.wallpaper` (blurred, or sharp under `rendering.quality` lite), `motion.reduced` and `rendering.quality` written to its `theme.conf.user`, and prints the `sudo` commands that install it to `/usr/share/sddm/themes/vados`, select it in `/etc/sddm.conf.d/theme.conf` and copy `profile.picture` to SDDM's faces. It never runs them. Run it again after changing those settings.
- A wrong password is shown the moment PAM answers, but `pam_unix` waits 2 s before answering. For a near-instant answer at the login screen only, add `nodelay` to `pam_unix.so` in `/etc/pam.d/sddm` (spelled out from `system-login` and `system-auth`, since an include cannot take options); `pam_faillock` still locks the account after three wrong tries.
- SDDM cannot read your home folder, so Space Mono must be installed system-wide (`ttf-space-mono`) for the login screen to use it.

## Network

The shell reaches the network only from these files, and only while the feature that needs it is on screen:

| File | Host | When |
|---|---|---|
| `services/Weather.qml` | api.open-meteo.com, geocoding-api.open-meteo.com; ipinfo.io when `weather.location` is empty | while the dashboard is open, a weather widget is on a screen that no fullscreen window covers, or the lock screen shows its weather module (not while blanked), at most every 15 minutes; after a failed request it retries after 1 s, doubling up to 1 minute |
| `services/Traffic.qml` | `ping` to 1.1.1.1 | while the dashboard is open |
| `utils/Family.js`, `services/Family.qml` | none itself; it hands a VAD/OS app's GitHub releases link to your browser through `xdg-open` | only when you press GET IT in settings (Advanced / Link to VAD/OS) |
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
| `appearance.systemFont` | font family every app uses, written to fontconfig and GTK from the settings window (Customization / System font); `""` leaves the system's own font | `""` |
| `appearance.choice` | how settings mark the chosen option: `outline` (a ring around it) or `pill` (filled) | `"outline"` |
| `appearance.choiceOutline` | colour of the outline marker, picked on the colour wheel in Settings; `""` follows the accent | `""` |
| `appearance.choicePill` | colour of the pill marker, picked on the same wheel; `""` follows the accent | `""` |
| `desktop.mode` | `"canvas"` / `"desktop"` (driftwm only) | `"canvas"` |
| `search.favorites` | desktop entry ids, e.g. `["firefox.desktop"]`; they lead the search list while the field is empty | `[]` |
| `search.hidden` | desktop entry ids the search leaves out unless HIDDEN is on | `[]` |
| `profile.name` | your name; its initial shows in the search circle when there is no picture | `""` |
| `profile.secondName` | optional second name | `""` |
| `profile.github` | your GitHub username | `""` |
| `pills.opacity` | 0 to 1, how opaque pills and overlay bodies are (settings, Customization / Pills) | `0.94` |
| `pills.blur` | 0 to 1, scales the liquid blur of every pill and overlay (settings, Customization / Pills) | `1` |
| `lock.layout` | lock screen modules as `"module:column:row"` on the 16 x 16 grid (modules `clock`, `profile`, `login` are required; `weather`, `music`, `dashboard`, `notifications` optional); edited in settings, Customization / Lock Screen | `["clock:5:1", "profile:6:4", "login:5:8"]` |
| `lock.wallpaper` | image path of the lock screen background, drawn heavily blurred; `""` uses `wallpaper.path`, or plain black without one | `""` |
| `lock.blankAfter` | seconds without input on the lock screen before the displays switch off (they wake to the lock on the next key or move); `0` never; set in Customization / Lock Screen. Only the locked screen blanks; the shell never locks on its own | `60` |
| `wallpaper.path` | image the shell draws as the desktop wallpaper on every screen, picked in Customization / Wallpaper; `""` draws none and leaves the compositor's own background (or another wallpaper tool). On driftwm, picking one also sets `[background]` (`type = "wallpaper"`, `path`) in `~/.config/driftwm/config.toml` and reloads driftwm's config; clearing it leaves that file alone | `""` |
| `wallpaper.folder` | folder the wallpaper picker lists images from (`jpg`, `jpeg`, `png`, `webp`, `bmp`); `""` uses `~/Pictures/Wallpapers` | `""` |
| `widgets.layout` | desktop widgets per monitor as `"monitor:widget:column:row"`, e.g. `["DP-1:clock:0:0"]`, on that monitor's grid of 88 px cells (widgets `clock`, `system`, `weather`, `network`, `battery`, `disk`, `notes`); placed in Customization / Widgets or by dragging a widget on the desktop. A monitor that comes back gets its widgets back, a new one starts empty | `[]` |
| `pills.color` | hex colour of every pill and overlay body; `""` is the default dark | `""` |
| `battery.limit` | `true`: the battery stops charging at 80% (Acer laptops with the `acer-wmi-battery` driver only; settings, Settings tab, BATTERY)<br>`false`: it charges to 100% | `false` |
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
