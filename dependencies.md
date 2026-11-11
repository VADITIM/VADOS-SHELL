# Dependencies

Everything the shell needs to run seamlessly, and what is lost without each. Package names are Arch Linux; other distributions use the same upstream projects. Keep this file current: a feature that starts a new program, imports a new module or reads a new system interface adds its row in the same change.

## Required

Without these the shell does not start or its core does not work.

| Dependency | Package | Used by | Without it |
|---|---|---|---|
| Quickshell | `quickshell` (AUR, or `quickshell-git`) | everything: `qs -p ~/.config/vados/shell` | nothing runs |
| Qt 6 Quick, Shapes, Effects, Wayland | `qt6-declarative`, `qt6-wayland` (pulled in by Quickshell) | every surface; `QtQuick.Shapes` (liquid, glyphs), `QtQuick.Effects` (`LiquidLayer`, `Masked`) | nothing renders |
| A Wayland compositor with `wlr-layer-shell` | `driftwm` (primary), `hyprland`, or another wlroots-style compositor | taskbar, overlays, alerts | nothing is shown; see README § Compositor support for what each one offers |
| Space Mono | `ttf-space-mono` (AUR) or the font files in `~/.local/share/fonts` | every text (`Appearance.font.mono`) | falls back to Consolas, DejaVu Sans Mono or Courier New; the layout is tuned for Space Mono |
| POSIX shell and coreutils | `bash` or `dash`, `coreutils` | `sh -c` probes, `mkdir`, `cp`, `rm` for runtime state (`StateFile`, clipboard images) | state files and probes fail |
| Python 3 | `python` | `scripts/processes.py` (dashboard task manager), `scripts/clipboard.py` (clipboard history), `scripts/pick-files.py` (file chooser) | task manager, clipboard history and file picking are empty |

## Features

Each row is needed only for the feature it names; the rest of the shell works without it.

| Dependency | Package | Feature | Without it |
|---|---|---|---|
| wl-clipboard (`wl-paste`, `wl-copy`) | `wl-clipboard` | clipboard history (`services/Clipboard.qml`, on by default), screenshots (PRINT, Ctrl+C), the frame debugger's screenshot (`KP_ADD`) | the clipboard history stays empty (its supervisor logs the failure and retries); screenshots are saved but not copied |
| grim | `grim` | screenshots (PRINT): freezes the screen through wlr-screencopy or ext-image-copy-capture (driftwm and Hyprland offer both) | PRINT does nothing; the log says grim failed |
| gpu-screen-recorder, or wf-recorder | `gpu-screen-recorder` (AUR) or `wf-recorder` | screen recording (SHIFT + PRINT); gpu-screen-recorder is preferred and the only one that can pause, wf-recorder records without pause or desktop audio | SHIFT + PRINT does nothing; the log says no recorder was found |
| PipeWire | `pipewire`, `wireplumber` | audio pill (volume, mute), Discord call detection, mic and deafen (`Quickshell.Services.Pipewire`) | no audio pill readings, no call activity |
| An MPRIS media player | Spotify, `mpv-mpris`, a browser | music in the activity pill (`Quickshell.Services.Mpris`) | no music activity |
| UPower | `upower` | battery pill and dashboard battery (`Quickshell.Services.UPower`) | no battery readings (desktops have none anyway) |
| StatusNotifierItem tray | apps that offer a tray icon | tray in the activity pill (`Quickshell.Services.SystemTray`) | the tray is empty |
| D-Bus and systemd tools (`busctl`, `systemctl`, `loginctl`) | `systemd` | notification daemon check (`busctl`), power pill: suspend, restart, shut down, lock (`systemctl`, `loginctl`) | the shell cannot tell who owns notifications; power actions do nothing |
| NetworkManager (`nmcli`) | `networkmanager` | Wi-Fi pill and its extension page: status, list, connect, radio on and off | no network pill readings or controls |
| udisks2, util-linux, udev (`udisksctl`, `lsblk`, `udevadm`) | `udisks2`, `util-linux`, `systemd` | USB pill: removable drives, eject | no USB pill |
| iputils (`ping`) | `iputils` | dashboard ping and jitter (to 1.1.1.1, only while the dashboard is open) | ping shows `--` |
| `/proc` and `/sys` (`/proc/stat`, `/proc/meminfo`, `/proc/cpuinfo`, `/proc/net`, `/sys/class/hwmon`, `/sys/class/drm`) | the Linux kernel | dashboard CPU, RAM, GPU (AMD), temperatures, traffic, task manager | readings show `--` |
| `nvidia-smi` | `nvidia-utils` | dashboard GPU on NVIDIA | NVIDIA GPU readings are missing (AMD reads `/sys`) |
| xdg-desktop-portal with a FileChooser backend, PyGObject | `xdg-desktop-portal`, `xdg-desktop-portal-gtk` (or `-kde`, `-gnome`), `python-gobject` | profile picture, files to send (`scripts/pick-files.py`) | the file chooser does not open |
| A file manager with `org.freedesktop.FileManager1`, or `xdg-open` | `nautilus`, `dolphin`, `thunar`; `xdg-utils` | task manager: Find path | Find path does nothing |
| Blip | `blip` | sending files from the notifications menu | the send tray is not shown |
| Notification clients | Discord, Telegram, WhatsApp and any other app | alerts and the notifications menu, with `notifications.enabled` (off by default; it replaces mako, dunst or swaync) | nothing to show |
| Network for the weather | api.open-meteo.com, ipinfo.io (README § Network) | dashboard weather | weather shows nothing |

## Compositor-specific

| Dependency | Feature | Without it |
|---|---|---|
| driftwm IPC (`driftwm msg`) | window geometry, fullscreen detection, focus, window modes (Canvas, Desktop), taskbar hiding on driftwm | the shell runs at the generic level |
| Hyprland IPC (`hyprctl`, `Quickshell.Hyprland`) and its `global` shortcut protocol | window geometry, focus, `vados:*` global shortcuts on Hyprland | bind keys to `qs ... ipc call` instead |
| A compositor blur rule | the blur behind overlays (Hyprland `layerrule = blur`, driftwm layer rules) | overlays dim but do not blur |

## Optional tuning

| Setting | Why |
|---|---|
| `MALLOC_CONF=thp:never,narenas:4,background_thread:true` in the environment that starts `qs` | the shell idles about 75 MB lower and gives memory back after an overlay closes (README § Memory) |
| `__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json` | keeps NVIDIA's EGL libraries out when no screen runs on the NVIDIA GPU |

## Development (Windows preview and tests)

| Dependency | Used by |
|---|---|
| Python 3 with PySide6 (installed under `C:\Users\vn\dependencies\pyside6`) | `tools/preview/play.py` (the preview), `tools/tests/run.py` (Qt Quick tests) |
| Qt's `qmltestrunner` | running the tests on Linux without PySide6 (`.claude/docs/quirks.md` § Memory) |
| Node.js | checking the pure `shell/utils/*.js` libraries by hand when Qt is not available |
| `qmlformat` (ships with PySide6) | syntax check of services that cannot be previewed |
