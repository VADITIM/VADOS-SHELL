# VAD/OS Shell

Arch + Hyprland shell built on [Quickshell](https://quickshell.org), following the V/AS design language.

## Install

Clone into `~/.config/vados`, then add to `hyprland.conf`:

```
exec-once = qs -p ~/.config/vados/shell
```

## Layout

```
shell/
├── shell.qml     entry point
├── config/       Config, Appearance (V/AS tokens), Motion
├── state/        shared UI state (the only sideways channel)
├── services/     data singletons, no UI
├── components/   V/AS primitives
├── modules/      features; never import each other
├── windows/      layer-shell hosts per screen
├── keybinds/     shortcuts + IPC, only change state
└── utils/
shell.json        user config
scripts/  assets/
```

Rule: data flows down, events flow up, nothing reaches sideways.

See [docs/project-notes.md](docs/project-notes.md) for design notes and build order.
