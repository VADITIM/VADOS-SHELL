# VAD/OS Shell

A desktop shell for Wayland, written in [Quickshell](https://quickshell.org) (Qt 6 / QML) on V/AS (VAD/OS APPLICATION SYSTEMS). Taskbar, search, dashboard, notifications, settings and lock screen in one piece, with a single liquid look and feel.

## Idea

VAD/OS Shell is one system. A Desktop environment established by a shell

It is built as independent subsystems (the liquid engine, overlays, gestures, attention, lifecycles) that are tested on their own, so new surfaces reuse the engine instead of inventing motion of their own. Animation is as strong as what a surface signals.


## Target

[driftwm](https://github.com/malbiruk/driftwm) first, built to run on every Wayland compositor like it, such as Hyprland: any compositor with layer-shell. The shell asks what a compositor can do, not which one it is, and degrades cleanly where something is missing. Taskbar, search and settings work everywhere; window modes need driftwm's free canvas.

## Features

**Taskbar**

**Search**

**Dashboard**

**Notifications**

**Clipboard Manager**

**Task Manager**

**Settings**

**Widgets**

**Capture**

**Custom SDDM Login**

**Custom boot splash**

> Everything lives in one live-reloaded `shell.json`, validated against a schema.

## Dependencies

The shell itself is QML and a few Python scripts; the rest comes from your system. Package names are Arch; the full table with what each one is used for and what is lost without it is in [dependencies.md](dependencies.md).

**Required**
- `quickshell` (0.2 or later, with its polkit module) and `qt6-declarative`, `qt6-wayland`
- A Wayland compositor with `wlr-layer-shell`: `driftwm`, `hyprland` or similar
- `ttf-space-mono` (the type the layout is tuned for), `python`, `bash` and `coreutils`

**Optional, per feature**
- Audio and music: `pipewire`, `wireplumber`, any MPRIS player
- Network and drives: `networkmanager` or `iwd` (with `python-gobject`), `udisks2`, `util-linux`
- Power and battery: `upower`, `power-profiles-daemon`, `brightnessctl`, `systemd`
- Clipboard and capture: `wl-clipboard`, `wtype`, `grim`, `gpu-screen-recorder` or `wf-recorder`
- Settings: `fontconfig`, `xkeyboard-config`, `xdg-utils`, `github-cli`, `xdg-desktop-portal` with a backend
- Lock screen: `pam`, and `wlopm` on driftwm to switch the displays off
- GPU readings: `nvidia-utils` on NVIDIA (AMD is read from `/sys`)

**Opt-in system roles** (off by default): the notification daemon (replaces mako, dunst or swaync), the polkit and keyring prompts (`polkit`, `gcr-4`, `gnome-keyring`), the SDDM login theme (`sddm`, `xorg-xrandr`) and the boot splash (`mkinitcpio`, `plymouth`, `librsvg`, `polkit`).

## Status

Early and moving fast; driftwm is the best-supported compositor. Installation is planned as an AUR package. See the [changelog](CHANGELOGS.md) for what has shipped, [dependencies.md](dependencies.md) for what the shell uses, and the [full reference](.claude/docs/readme-full.md) for keybindings, compositor support, settings keys and development notes.
