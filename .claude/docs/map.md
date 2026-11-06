# Map

| Path | Purpose |
|---|---|
| `shell/shell.qml` | Entry: `Shortcuts`, one `TaskbarWindow`, `SearchWindow`, `SettingsWindow` and `DashboardWindow` per screen |
| `shell/config/Config.qml` | `shell.json` adapter and setters (`setTaskbarStyle`, `setTaskbarSide`, `setTaskbarCompact`, `setAccent`, `setWindowMode`, `setWeatherLocation`, `toggleFavorite`) |
| `shell/config/Appearance.qml` | V/AS tokens: colour (accent read live from `Config`, level bands), font, radius, `taskbar`, `settings`, `desktop`, `burst`, `dashboard` (+ `gauge`, `memory`, `weather`), `search`, `activity` (+ `media`, `call`); `bandColor(value, limits)` |
| `shell/config/Motion.qml` | Every duration and physics constant: `pill`, `hover`, `fold`, `reveal`, `carry`, `settings`, `desktop`, `dashboard` (dim, reveal, polling), `burst`, `press`, `search`, `activity`, springs |
| `shell/state/ActivityState.qml` | The activity pill's state (`hidden`, `idle`, `active`, `expanded`), the screen it is expanded on, the lead activity; `step`, `set`, `rotate`, `modeOn(screen)`; turns active or idle when activities start or all stop |
| `shell/state/Visibilities.qml` | Which overlay (search, settings, dashboard) is open and on which screen; `taskbarGathering`, edge-relative taskbar parts and gear origins, which screen's taskbar is away, and the leaving overlay ball each taskbar reacts to (`visitors`) |
| `shell/services/Compositor.qml` | **The WM boundary**: backend detection, driftwm subscribe stream, Hyprland queries, generic fallback, `send`/`action` |
| `shell/services/Occupancy.qml` | Whether the active window covers the taskbar on a screen |
| `shell/services/Confinement.qml` | Desktop mode on driftwm: park/restore (minimize), camera lock, confine, cascade, snap |
| `shell/services/Toplevels.qml` | Wayland toplevels grouped by app; `activate` routes through `Confinement` in Desktop mode |
| `shell/services/Apps.qml` | Desktop entries, fuzzy search, launch history (`~/.cache/vados/apps.json`) |
| `shell/services/{Audio,Battery,Network,Power,Removable,DateTime}.qml` | Idle pill data |
| `shell/services/Activities.qml` | What is running now: MPRIS player (the playing one first, then Spotify), Discord voice call from its PipeWire streams (mic and deafen mute those streams), call time; `keys`, `liveKeys`, `order` (live first) |
| `shell/services/Tray.qml` | System tray items, `open` / `openMenu`; unused since the `...` pill went, kept for the activity bar |
| `shell/services/Hardware.qml` | CPU load, temperature and name, RAM, GPU (`nvidia-smi` or amdgpu sysfs), disks; polls only while `isActive` |
| `shell/services/Weather.qml` | Open-Meteo current reading and 6-day forecast; location from `weather.location` or an IP lookup |
| `shell/services/Traffic.qml` | Network throughput from `/proc/net/dev` every second (last 60 samples kept always); `ping` to 1.1.1.1 for latency and jitter only while `isActive` (dashboard open) |
| `shell/components/LiquidLayer.qml` | Goo material: blur + threshold of everything in `shapes` |
| `shell/components/{LiquidShape,LiquidBridge,EdgeFuse}.qml` | Liquid primitives: round body, neck between bodies, fuse into the screen edge |
| `shell/components/Gather.qml` | Taskbar silhouettes inside an overlay's liquid, pulled into one point |
| `shell/components/Rising.qml` | Pooled bubbles rising off a body's top and bottom to the screen edges |
| `shell/components/Burst.qml` | Ability: overlay body (dashboard, search) born from the taskbar parts at the taskbar column, fused to the screen edge, exploding into its form with wall surges, crests and splashes; optional steps (`hasSteps`, `hasSideStep`); its own leave |
| `shell/components/Press.qml` | Ability: press and raise scale feedback on a target item |
| `shell/components/EdgePull.qml` | Ability: taskbar edge strip; hover dwell and drag pull grow a bead and summon the bar |
| `shell/components/Jolt.qml` | Haptic ability: keyframed bounce value on `kick()` |
| `shell/components/Launch.qml` | Ability: the settings body; taskbar merges into the gear, the ball flies to the centre and pops into the panel with trail, splashes and tab bar bud; its own leave |
| `shell/components/Lobe.qml` | Cubic `Shape` flaring into the screen edge: the root side of a `Burst` body and of the handed-off leaving ball |
| `shell/components/Reshape.qml` | Ability: a body's width and height follow target sizes; grow leads on the axis that changes most and overshoots, shrink waits for the content and is faster; cue `isArrived` |
| `shell/components/Mutate.qml` | Ability: pill pop and spread enter, own leave, inner reveal cue (task pills, idle circles) |
| `shell/components/ColorWheel.qml` | Hue/saturation wheel, value slider, swatch and hex field (port of vados-notes `ColorPanel`) |
| `shell/components/Upright.qml` | Counter-flip transform that keeps text and icons readable inside the mirrored taskbar |
| `shell/components/Turn.qml` | Flip enter/leave used by every piece that comes and goes |
| `shell/components/{Glyph,GlyphButton,TypedText,Surface}.qml` | Icons (SVG path table), icon button, typed text, panel |
| `shell/modules/taskbar/` | Taskbar: `Taskbar` root, `TaskPill`/`TaskItem`, idle pills (`SettingsIdle` above `PowerIdle`), `FoldDot` (compact column bead), `FoldDrag` (idle pointer area with the fold gesture), `Carried` drag droplet, `Arrangement`, `TitleTip`; activity pill: `ActivityPill` (body, states, satellites, clicks), `ActivityGlance` (active face per activity), `ActivityBars`, expanded views `ActivityMedia` (disc head, progress ring, controls) and `ActivityCall` (call time, mic and deafen drops) |
| `shell/modules/extension/` | Extension: `Extension` root (the pill grown to full height over the taskbar, own liquid layer, loads a page by key), `NetworkPage` (Wi-Fi header + list), `NetworkRow` |
| `shell/modules/settings/` | Settings: `Settings` root (taskbar-to-panel morph: merge, hop, shoot, pop, bud; pages), `TabBar` pop bar, `Page` tab page flip, `OptionGroup` labelled choice row |
| `shell/modules/search/` | Search: `Search` root (`Burst` column, traced wall `Shape` and its favourites mask, layout, keys), `ResultRow` (list row; `room` shrinks it beside the best match, `fade` under the favourites), `FoundCard` (best match circle and its name pill), `AppTile` (favourite), `AppIcon` |
| `shell/modules/dashboard/` | Dashboard: `Dashboard` root (layout, `Burst` body, content), `Gauge` (generic ring + chip: CPU, GPU with VRAM `Crescent`, RAM), `Ring`, `Crescent` (quarter arc level), name and caption set on the ring with `components/ArcText`, `LevelBar`, `Throughput` (download/upload graph of the last 60 s with ping and jitter, under RAM), `Drive` (disk readout in the bottom step's notch), `Charge` (battery in the far-wall notch, laptops), `Forecast`, `Vacant` placeholder |
| `shell/windows/` | `TaskbarWindow`, `SearchWindow`, `SettingsWindow`, `DashboardWindow` layer-shell hosts |
| `shell/keybinds/Shortcuts.qml` | Hyprland global shortcuts `search`, `settings`, `dashboard`, `activityNext`, `activityPrevious` + IPC targets `search`, `settings`, `dashboard`, `desktop` and `activity` |
| `shell/utils/Fuzzy.js` | Match scoring, frecency, ranking |
| `shell/modules/{alerts,canvas,notifications,widgets}/` | Empty, planned (`roadmap.md`) |
| `shelf/dashboard-wave/` | Shelved: the dashboard's pour-out wave with idle ripple (`Wave.qml`, the old `Dashboard.qml`, `README.md` with its tokens); not loaded |
| `tools/preview/` | Windows playground: `play.py` builds a mock `qs.*` tree (real config, components, state and modules; mocked `Config`, services) and runs `play.qml` with taskbar, search, settings and dashboard together (`D` / `Ctrl+D`) |
| `.claude/hooks/docs-current.py` | Stop hook that keeps these docs current |

Where to change things:

- When the taskbar hides: `Occupancy.qml` (the rule) and `Compositor.qml` (the geometry).
- Any speed: `Motion.qml`.
- Adding a WM: a backend branch in `Compositor.qml` only.
