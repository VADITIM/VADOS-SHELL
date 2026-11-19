# Dependencies

Everything the shell needs to run seamlessly, and what is lost without each. Package names are Arch Linux; other distributions use the same upstream projects. Keep this file current: a feature that starts a new program, imports a new module or reads a new system interface adds its row in the same change.

## Required

Without these the shell does not start or its core does not work.

| Dependency | Package | Used by | Without it |
|---|---|---|---|
| Quickshell | `quickshell` (AUR, or `quickshell-git`) | everything: `qs -p ~/.config/vados/shell`; its `Quickshell.Services.Polkit` module (0.2 or later) for the admin password prompt | nothing runs; without the polkit module the shell does not load |
| Qt 6 Quick, Shapes, Effects, Wayland | `qt6-declarative`, `qt6-wayland` (pulled in by Quickshell) | every surface; `QtQuick.Shapes` (liquid, glyphs), `QtQuick.Effects` (`LiquidLayer`, `Masked`), `Qt.labs.folderlistmodel` (the wallpaper list) | nothing renders |
| A Wayland compositor with `wlr-layer-shell` | `driftwm` (primary), `hyprland`, or another wlroots-style compositor | taskbar, overlays, alerts | nothing is shown; see README § Compositor support for what each one offers |
| Space Mono | `ttf-space-mono` (AUR) or the font files in `~/.local/share/fonts` | every text (`Appearance.font.mono`) | falls back to Consolas, DejaVu Sans Mono or Courier New; the layout is tuned for Space Mono |
| POSIX shell and coreutils | `bash` or `dash`, `coreutils` | `sh -c` probes, `mkdir`, `cp`, `rm` for runtime state (`StateFile`, clipboard images) | state files and probes fail |
| Python 3 | `python` | `scripts/processes.py` (dashboard task manager), `scripts/clipboard.py` (clipboard history), `scripts/pick-files.py` (file chooser) | task manager, clipboard history and file picking are empty |

## Features

Each row is needed only for the feature it names; the rest of the shell works without it.

| Dependency | Package | Feature | Without it |
|---|---|---|---|
| `acer-wmi-battery` (charge limit) | `acer-wmi-battery-dkms-git` (AUR), plus the tmpfiles rule in README § Battery charge limit | `services/Battery.qml` through `scripts/charge-limit.py`; reads `/sys/class/dmi/id/sys_vendor` | the BATTERY section never shows; only Acer laptops have it |
| wl-clipboard (`wl-paste`, `wl-copy`) | `wl-clipboard` | clipboard history (`services/Clipboard.qml`, on by default), screenshots (PRINT, Ctrl+C), the frame debugger's screenshot (`KP_ADD`) | the clipboard history stays empty (its supervisor logs the failure and retries); screenshots are saved but not copied |
| wtype | `wtype` | pasting a picked clipboard entry (`services/Clipboard.qml`, Ctrl+V into the focused window) | the entry is copied and moved to the front but not pasted; the failure is logged |
| grim | `grim` | screenshots (PRINT): freezes the screen through wlr-screencopy or ext-image-copy-capture (driftwm and Hyprland offer both) | PRINT does nothing; the log says grim failed |
| gpu-screen-recorder, or wf-recorder | `gpu-screen-recorder` (AUR) or `wf-recorder` | screen recording (SHIFT + PRINT); gpu-screen-recorder is preferred and the only one that can pause, wf-recorder records without pause or desktop audio | SHIFT + PRINT does nothing; the log says no recorder was found |
| PipeWire | `pipewire`, `wireplumber` | audio pill (volume, mute), Discord call detection, mic and deafen (`Quickshell.Services.Pipewire`) | no audio pill readings, no call activity |
| pw-metadata | `pipewire` | moving an audio stream to another output (audio extension page) | streams cannot be moved; devices and volumes still work |
| power-profiles-daemon (`powerprofilesctl`) | `power-profiles-daemon` | power profiles in the battery pill's POWER page | no profile rows |
| fontconfig (`fc-list`), gsettings | `fontconfig`, `glib2` | settings, System font: lists families, and sets GTK's `font-name` | no families listed; without gsettings only the fontconfig alias is written |
| xkeyboard-config (`/usr/share/X11/xkb/rules/evdev.lst`) | `xkeyboard-config` | settings, Keyboard: the layouts and variants to pick from | no layouts listed |
| hidraw (`/dev/hidraw*`), `python3` (`lzma`), `pkexec` | kernel, `python`, `polkit` | settings, Keyboard: reads and writes VIA/Vial keymaps (`scripts/keyboards.py`) | no REMAP; without access READ AS ADMIN asks through polkit |
| GitHub CLI, signed in (`gh auth login`) | `github-cli` | settings, User: the GitHub calendar, pinned and owned repositories, push headlines | the box reads public activity of the typed name only: no calendar beyond pushes, no favorites import from pins, pushes say only their branch |
| xdg-utils (`xdg-mime`, `xdg-open`) | `xdg-utils` | settings, Link to VAD/OS: reads and sets default apps, opens a releases page | defaults are not shown or set; GET IT does nothing |
| brightnessctl | `brightnessctl` | the brightness slider in the POWER page | no brightness row |
| An MPRIS media player | Spotify, `mpv-mpris`, a browser | music in the activity pill (`Quickshell.Services.Mpris`) | no music activity |
| UPower | `upower` | battery pill, dashboard battery and the battery widget (`Quickshell.Services.UPower`) | no battery readings (desktops have none anyway) |
| StatusNotifierItem tray | apps that offer a tray icon | tray in the activity pill (`Quickshell.Services.SystemTray`) | the tray is empty |
| D-Bus and systemd tools (`busctl`, `systemctl`, `loginctl`) | `systemd` | notification daemon check (`busctl`), power pill: suspend, restart, shut down, lock (`systemctl`, `loginctl`) | the shell cannot tell who owns notifications; power actions do nothing |
| NetworkManager (`nmcli`) or iwd (`iwctl`) | `networkmanager` or `iwd` | Wi-Fi pill and its extension page: status, list, join with a password or a sign-in, hidden networks, forget, radio on and off; an 802.1X sign-in on iwd is written through `pkexec` (`polkit` and a running polkit agent); joining runs `scripts/wifi.py`, which needs `python-gobject` (an iwd D-Bus agent; the user must be in the `wheel` or `network` group for iwd's D-Bus policy) | no network pill readings or controls |
| udisks2, util-linux, udev (`udisksctl`, `lsblk`, `udevadm`) | `udisks2`, `util-linux`, `systemd` | USB pill: removable drives, eject | no USB pill |
| iputils (`ping`) | `iputils` | dashboard ping and jitter (to 1.1.1.1, only while the dashboard is open) | ping shows `--` |
| `/proc` and `/sys` (`/proc/stat`, `/proc/meminfo`, `/proc/cpuinfo`, `/proc/net`, `/sys/class/hwmon`, `/sys/class/drm`) | the Linux kernel | dashboard CPU, RAM, GPU (AMD), temperatures, traffic, task manager; the System, Disk and Network widgets | readings show `--` |
| `nvidia-smi` | `nvidia-utils` | dashboard GPU and the System widget's GPU ring on NVIDIA | NVIDIA GPU readings are missing (AMD reads `/sys`) |
| xdg-desktop-portal with a FileChooser backend, PyGObject | `xdg-desktop-portal`, `xdg-desktop-portal-gtk` (or `-kde`, `-gnome`), `python-gobject` | profile picture, files to send (`scripts/pick-files.py`) | the file chooser does not open |
| A file manager with `org.freedesktop.FileManager1`, or `xdg-open` | `nautilus`, `dolphin`, `thunar`; `xdg-utils` | task manager: Find path | Find path does nothing |
| Blip | `blip` | sending files from the notifications menu | the send tray is not shown |
| Notification clients | Discord, Telegram, WhatsApp and any other app | alerts and the notifications menu, with `notifications.enabled` (off by default; it replaces mako, dunst or swaync) | nothing to show |
| Network for the weather | api.open-meteo.com, ipinfo.io (README § Network) | dashboard weather, the Weather widget and the lock screen's weather module | weather shows nothing |
| PAM (`/etc/pam.d/login`) and `Quickshell.Services.Pam` | `pam`, `quickshell` | unlocking the lock screen (`services/Lock.qml`, service `login`) | the lock shows AUTHENTICATION COULD NOT START and stays locked (README § Lock screen) |
| ext-session-lock and ext-idle-notify (`Quickshell.Wayland` `WlSessionLock`, `IdleMonitor`) | the compositor (driftwm, Hyprland) | the lock screen (`windows/LockWindow.qml`) and blanking the locked screen after `lock.blankAfter` | no lock screen: the lock button hands over to `loginctl lock-session`; without idle notification the locked screen never blanks |
| wlr-output-management, Python 3 | the compositor (driftwm), `python` | reading the monitors and their modes for the Displays tab on driftwm (`scripts/outputs.py`, read only, no Python packages) | the Displays tab shows NO MONITORS FOUND |
| wlopm | `wlopm` (extra) | switching the displays off and on while locked on driftwm (wlr-output-power-management, `Compositor.powerDisplays`) | the locked screen turns black but the displays stay on |
| `/etc/os-release`, `/proc/sys/kernel/osrelease`, `/proc/sys/kernel/hostname`, `/proc/uptime` | the distribution, the Linux kernel | the system rows on the Settings > User tab | the row shows `-` |
| `/proc/sys/kernel/random/boot_id`, `XDG_SESSION_ID` | the Linux kernel, `systemd-logind` | locking again when the shell restarts inside a locked session | a restarted shell leaves the crashed lock blank (the session stays locked) |

## Login screen

Only for the SDDM theme in `sddm/vados` (README § Login screen); the shell never needs these.

| Dependency | Package | Used by | Without it |
|---|---|---|---|
| SDDM 0.21 or later with its Qt 6 greeter | `sddm` | the login screen (`sddm-greeter-qt6`, `QtVersion=6` in `metadata.desktop`) | the theme is not used; any other login manager works as before |
| Qt 6 Quick Effects | `qt6-declarative` | the blurred wallpaper and the round profile picture (`MultiEffect`) | the theme does not load |
| Space Mono, installed system-wide | `ttf-space-mono` (AUR) | the login screen's type; SDDM cannot read `~/.local/share/fonts` | falls back to DejaVu Sans Mono |
| xrandr | `xorg-xrandr` | the login screen on every monitor (`sddm/vados/Xsetup`) | only the outputs Xorg turns on by itself show the login |
| Python 3 | `python` | `sddm/install.py` (staging, preview) | install by hand: copy `sddm/vados` and write `theme.conf.user` |

## Boot screen

Only for the BOOT switches in Advanced / Services (README § Boot screen); without these the section is hidden or its PLYMOUTH row is.

| Dependency | Package | Used by | Without it |
|---|---|---|---|
| mkinitcpio building a unified kernel image | `mkinitcpio`, `systemd` (`systemd-stub`) | SPLASH and PLYMOUTH: `scripts/boot.py` edits the presets and runs `mkinitcpio -P` | the BOOT section is hidden |
| Plymouth | `plymouth` | PLYMOUTH: the `plymouth` mkinitcpio hook and the `vados` script theme | only SPLASH shows, with INSTALL PLYMOUTH FOR THE ANIMATED BOOT SCREEN |
| rsvg-convert | `librsvg` | drawing the mark in your accent (`assets/boot/mark.svg`) | the BOOT section is hidden |
| polkit (`pkexec`) and a running polkit agent | `polkit`, `polkit-gnome` or `polkit-kde-agent` | running `scripts/boot.py apply` and `scripts/login.py apply` as root | the switch does nothing and the section says NO POLKIT AGENT RUNNING |
| `/etc/kernel/cmdline` | `mkinitcpio` | PLYMOUTH adds `quiet splash` to the command line baked into the image | only SPLASH shows |

## Compositor-specific

| Dependency | Feature | Without it |
|---|---|---|
| driftwm IPC (`driftwm msg`) | window geometry, fullscreen detection, focus, window modes (Canvas, Desktop), taskbar hiding on driftwm | the shell runs at the generic level |
| driftwm's config file (`$XDG_CONFIG_HOME/driftwm/config.toml`) and its live reload | the wallpaper and the Displays tab's `[[outputs]]`; turning a monitor off needs driftwm built with `~/aur/driftwm-git-local/disable-outputs.patch` (`enabled = false`) | without the file nothing is written; the Displays tab refuses to apply; without the patch driftwm refuses a config with a monitor off and the countdown reverts it |
| Hyprland IPC (`hyprctl`, `Quickshell.Hyprland`) and its `global` shortcut protocol | window geometry, focus, `vados:*` global shortcuts on Hyprland, `hyprctl dispatch dpms` for blanking the locked screen, `hyprctl -j monitors all` and `keyword monitor` for the Displays tab (a kept layout goes to `~/.config/hypr/vados-displays.conf`, which `hyprland.conf` sources) | bind keys to `qs ... ipc call` instead |
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

## Password prompts (`prompts.enabled`)

| Needs | Package (Arch) | For | Without it |
|---|---|---|---|
| polkit | `polkit` | the admin password prompt (the shell as the polkit agent) | nothing asks for admin rights through the shell |
| gcr 4 with its GObject introspection data, and PyGObject | `gcr-4`, `python-gobject` | `scripts/keyring.py`, the keyring prompt (secret exchange) | the helper exits, the supervisor logs it, `gcr-prompter` keeps asking |
| gnome-keyring | `gnome-keyring` | something to prompt for | no keyring prompts appear |
