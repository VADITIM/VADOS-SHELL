# VAD/OS Shell – Project Notes

Project description plus a summary of the three chats in this project (Nov 4, 2026).

---

## Project description

**VAD/OS SHELL** is an Arch Hyprland Quickshell built specifically around V/AS.

- A big interactive system living in Quickshell, modifying every aspect and small detail of an operating system.
- Built-in core features aligned with the V/AS design language, establishing unified unit sizes for consistency across systems and VAD/OS family apps.
- Meant to establish the core pillars and be the most polished interactive system across the VAD/OS family.
- Overlay-based UI, haptic and hover interactions, and reactive animations driven by interaction.
- Responsive, physics-based animation across the whole shell: liquidity across modules, a unified modular system that interacts as one rather than as individual parts.
- Establishes new core pillars for V/AS, such as unified icons stored directly inside V/AS.
- Pushes motion logic to its limits: fast, responsive, visual animations tuned between speed and responsiveness, with clear visual hierarchy and reactions.

---

## 1. Pannable canvas desktop in Hyprland

**Goal:** A pannable desktop where apps can be moved freely, snap back to the center when needed, and can be locked in place, plus a traditional (tiled) mode on a button press.

**Findings**
- Hyprland has no native infinite canvas. It can be approximated through IPC (`hyprctl`) by moving floating windows.
- Panning = moving all floating windows by the same delta. Windows may sit at negative or off-screen coordinates, so the canvas is unbounded.
- "Fix to center" = shift the bounding box of all windows so its center matches the monitor center.
- "Locked" apps = `pin`, or exclude them from the pan script via class or tag.
- Traditional mode = save geometry, then tile. Toggling back restores the saved positions.

**Script concept** (`~/.config/hypr/canvas.sh`): subcommands `pan dx dy`, `recenter`, `save`, `restore`, `tile`, driven by `hyprctl clients -j` + `movewindowpixel`.

**Suggested binds**
- `SUPER ALT + arrows` → pan
- `SUPER + C` → recenter
- `SUPER + T` → tile
- `SUPER SHIFT + T` → restore

**Notes**
- Auto-recenter: a small daemon listening on Hyprland's `socket2` events.
- Smooth panning: `movewindowpixel` jumps, so use many small steps for a smooth feel.
- Mouse-drag panning: possible via `hyprctl cursorpos` deltas.
- The built-in scrolling layout is closer to a pannable strip and worth trying first.
- Risk: runaway panning can push windows far off-screen, so keep a recenter bind.

---

## 2. Hyprland window animation direction

**Problem:** Windows animate toward the right and bottom when expanding. Goal: expand in every direction.

**Findings**
- No single built-in setting for "expand from all sides".
- Open/close uses `windowsIn` / `windowsOut`. The `slide` style enters from the nearest screen edge.
- Resize/move uses `windowsMove`, which interpolates position and size linearly, so the top-left corner moves and the bottom-right grows.
- Closest built-in option: `popin` (scales from center), which only helps open/close, not resizing.

```
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windowsIn, 1, 4, myBezier, popin 60%
    animation = windowsOut, 1, 4, myBezier, popin 60%
    animation = windowsMove, 1, 4, myBezier
    animation = fade, 1, 4, default
}
```

**True all-direction resize** needs a plugin (custom geometry animation hook) or a scripted stepwise resize/move (hacky, less smooth). This is a candidate to handle inside the shell's canvas module.

---

## 3. Shell architecture (Caelestia-style, Quickshell)

**Answer:** Yes, the whole VAD/OS shell can live in its own folder (`~/.config/vados/`) and be started with `qs -p ~/.config/vados/shell`. Only one line in the Hyprland config is needed: `exec-once = qs -p ~/.config/vados/shell`.

**Core rule:** data flows down, events flow up, nothing reaches sideways.

```
config → services → components → modules → windows → shell.qml
```

- **Services:** singletons holding data, no UI.
- **Components:** V/AS primitives (surfaces, buttons, motion).
- **Modules:** features that read services and compose components. Modules never import each other.
- **Windows:** layer-shell hosts per screen.
- **state/:** shared UI state (e.g. `Visibilities`), the only "sideways" channel.
- **keybinds/:** only change state or call IPC, never do work themselves.

**Folder layout**

```
~/.config/vados/
├── shell/
│   ├── shell.qml
│   ├── config/        Config, Appearance, Motion
│   ├── state/         Visibilities, Focus
│   ├── services/      DateTime, Weather, Process, Audio, Network, Battery,
│   │                  Notifs, Tray, Toplevels, Apps, Media
│   ├── components/    Surface, VButton, Icon, anim/
│   ├── modules/       taskbar (Tasks, Idle), dashboard, notifications,
│   │                  alerts, search, widgets, canvas
│   ├── windows/       BarWindow, OverlayWindow, CanvasWindow
│   ├── keybinds/      Shortcuts, Ipc
│   └── utils/
├── shell.json
├── scripts/
├── assets/
└── cache/ → ~/.cache/vados
```

**Design choices**
- Notifications (history/center) and Alerts (transient OSDs/toasts) are separate modules sharing one `Notifs` service.
- One overlay window per screen hosts all panels, which enables cross-panel animations.
- Keybinds, CLI (`qs ipc call vados toggle dashboard`) and clicks all go through the same state/IPC path.

**Build order**
1. config + components (V/AS tokens, motion)
2. BarWindow + DateTime + Toplevels (taskbar with tasks)
3. Tray (Idle area)
4. state + OverlayWindow + Search
5. Notifs → Alerts → Notification center
6. Process, Weather, Media → Dashboard
7. Canvas (most custom, built last)

**Open offer:** scaffold the full folder with `qmldir`s, stubs and a working bar.

---

## How the three fit together

The pannable canvas (chat 1) and the all-direction window animation (chat 2) become the `modules/canvas` + `windows/CanvasWindow` layer in the shell (chat 3). The shell hierarchy keeps them isolated from the bar, dashboard and other modules.
