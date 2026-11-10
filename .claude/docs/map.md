# Map

| Path | Purpose |
|---|---|
| `shell/shell.qml` | Entry: `Shortcuts`, one `TaskbarWindow`, `SearchWindow`, `SettingsWindow` and `DashboardWindow` per screen |
| `shell/config/Config.qml` | `shell.json` adapter and setters (`setTaskbarStyle`, `setTaskbarSide`, `setTaskbarCompact`, `setAccent`, `setWindowMode`, `setWeatherLocation`, `setReducedMotion`, `setRenderQuality`, `setDoNotDisturb`, `setNotificationsEnabled`, `setProfile`, `toggleFavorite`); validates and migrates the file on load through `utils/Schema.js` and refuses invalid values in setters |
| `shell/config/Appearance.qml` | V/AS tokens: colour (accent read live from `Config`, level bands), font, radius, `liquid` (the goo material: fill, rim and core thresholds), `taskbar`, `settings`, `desktop`, `burst`, `dashboard` (+ `gauge`, `memory`, `weather`), `search`, `activity` (+ `media`, `call`); `bandColor(value, limits)` |
| `shell/config/Motion.qml` | Every duration and physics constant: `pill`, `hover`, `fold`, `reveal`, `carry`, `settings`, `desktop`, `dashboard` (dim, reveal, polling), `burst`, `press`, `search`, `activity`, `store`, `supervision` (restart backoff), `attention`, `gesture`, `liquid` (the liquid engine's characters and clock); `isReduced` and `pace()` for reduced motion |
| `shell/utils/Features.js` | **Feature registry**: one row per surface, built or planned (`key`, `folder`, `root`, `surface`, `origin`, `impact`, `needs`, `isBuilt`, `layer`); `overlayKinds()` feeds `Overlays.kinds`; `check-rules.py` holds it against the tree |
| `shell/state/Overlays.qml` | **Overlay engine**: `kinds` (the built overlay rows of `Features.js`), open/close/toggle with layer exclusion, keyboard owner (`top`), taskbar gather and per-screen return, parts, per-overlay leaving balls (`visitorOn`), each surface's lifecycle phase (`phaseOf`, `isSettled`), screens that went away (`keepScreens`) |
| `shell/state/FrameDebug.qml` | **Frame debugger**: `KP_0` sets `Motion.isHeld` (every animation pauses), `step()` runs one frame (or moves forward through the recording), `back()` goes back, `snap()` makes the screenshot; keeps the last `Motion.frames.history` frames (within `Motion.frames.memory`) as full-resolution pictures from the `FrameTap`s |
| `shell/utils/Playing.js` | Registry of everything that can say what it is playing (`Lifecycle`, `Mutate`): `enlist`, `delist`, `names()`; the frame debugger's source of animation names |
| `shell/windows/FrameTap.qml` | Grabs its window content (`grabToImage`) on every `FrameDebug` capture request and stores it with the screen and side |
| `shell/windows/FrameWindow.qml` | Click-through per-screen window hosting the HUD; takes the keyboard on the screen that started the hold; renders the screenshot and copies it with `wl-copy` |
| `shell/modules/framedebug/FrameHud.qml` | The HUD: `FRAME n`, the animation names and the key hint top right, the replayed picture, the hidden screenshot stage; keys Up and Right step, Down and Left go back, Plus copies, Escape resumes |
| `shell/modules/framedebug/FrameStage.qml` | Dark ground with the grabbed pictures of one frame laid out as on screen |
| `shell/state/Attention.qml` | **Attention engine**: whether a notification may interrupt (critical, quiet, fullscreen, low), batching into one `peek`, its expiry |
| `shell/state/Activity.qml` | Activity bar state: which screen it is open on, the pinned activity, and the merged `entries` (notifications, tray) with the `current` one to show |
| `shell/state/ActivityState.qml` | The activity pill's state (`hidden`, `idle`, `active`, `expanded`), the screen it is expanded on, the lead activity; `step`, `set`, `rotate`, `modeOn(screen)`; turns active or idle when activities start or all stop |
| `shell/services/Compositor.qml` | **The WM boundary**: backend detection, driftwm subscribe stream, Hyprland queries, generic fallback, `send`/`action` |
| `shell/services/Occupancy.qml` | Whether the active window covers the taskbar on a screen |
| `shell/services/Confinement.qml` | Desktop mode on driftwm: park/restore (minimize), camera lock, confine, cascade, snap |
| `shell/services/Toplevels.qml` | Wayland toplevels grouped by app; `activate` routes through `Confinement` in Desktop mode |
| `shell/services/Apps.qml` | Desktop entries, fuzzy search, launch history (`~/.cache/vados/apps.json`) |
| `shell/services/{Audio,Battery,Network,Power,Removable,DateTime}.qml` | Idle pill data |
| `shell/services/Activities.qml` | What is running now: MPRIS player (the playing one first, then Spotify), Discord voice call from its PipeWire streams (mic and deafen mute those streams), call time; `keys`, `liveKeys`, `order` (live first) |
| `shell/services/Tray.qml` | System tray items, `open` / `openMenu`; unused since the `...` pill went, kept for the activity bar |
| `shell/services/Supervisor.qml` | **Supervision**: a reusable type that keeps a `Process` (or any retried work, `fail` / `succeed` / `restarted`) running while `isActive`, restarting with backoff (`utils/Backoff.js`, `Motion.supervision`) and logging failures and recoveries; used by `Compositor`, `Network`, `Removable`, `Traffic`, `Weather` |
| `shell/services/Supervision.qml` | Registry of every `Supervisor` (`supervisors`, `enroll`, `release`) for diagnostics |
| `shell/services/StateFile.qml` | **Persistence**: versioned runtime state in `~/.cache/vados/<name>.json`, debounced writes, corrupt and version files kept aside |
| `shell/services/Notifications.qml` | Desktop notification server (only while `notifications.enabled`): `list` newest first, `latest`, unread tracking, `dismiss`, `clear`, `invoke`, `received` |
| `shell/services/Hardware.qml` | CPU load, temperature and name, RAM, GPU (`nvidia-smi` or amdgpu sysfs), disks; polls only while `isActive` |
| `shell/services/Weather.qml` | Open-Meteo current reading and 6-day forecast; location from `weather.location` or an IP lookup |
| `shell/services/Traffic.qml` | Network throughput from `/proc/net/dev` every second (last 60 samples kept always); `ping` to 1.1.1.1 for latency and jitter only while `isActive` (dashboard open) |
| `shell/config/Release.qml` | **Release**: the shell's `version`, shown on the settings home page; bumped with the changelog heading |
| `shell/config/Rendering.qml` | **Rendering quality**: `isLite` from `rendering.quality`, `blur(radius)`, the precedence function for blur |
| `shell/components/LiquidLayer.qml` | **Rendering**: goo material, blur + threshold of everything in `shapes`; renders only while `isShown` and not transparent, no blur under lite |
| `shell/components/Masked.qml` | **Rendering**: content cut by the shape in `mask` (search favourites by the wall, the best-match avatar); layers only while visible |
| `shell/components/{LiquidShape,LiquidBridge,EdgeFuse}.qml` | Liquid primitives: round body, neck between bodies, fuse into the screen edge |
| `shell/components/Gather.qml` | Taskbar silhouettes inside an overlay's liquid, pulled into one point |
| `shell/components/Rising.qml` | Pooled bubbles rising off a body's top and bottom to the screen edges |
| `shell/components/Burst.qml` | Ability: overlay body (dashboard, search) born from the taskbar parts at the taskbar column, fused to the screen edge, exploding into its form with wall surges, crests and splashes; optional steps (`hasSteps`, `hasSideStep`); its own leave |
| `shell/components/Press.qml` | Ability: press and raise scale feedback on a target item |
| `shell/components/EdgePull.qml` | Ability: taskbar edge strip; hover dwell and drag pull grow a bead and summon the bar |
| `shell/components/Lobe.qml` | Cubic `Shape` flaring into the screen edge: the root side of a `Burst` body and of the handed-off leaving ball |
| `shell/components/Reshape.qml` | Ability: a body's width and height follow target sizes; grow leads on the axis that changes most and overshoots, shrink waits for the content and is faster; cue `isArrived` |
| `shell/components/Gesture.qml` | **Gesture engine**: drag ability with threshold, travel, velocity, `moved` / `crossed` / `thrown` / `tapped` / `ended` |
| `shell/components/Lifecycle.qml` | **Transition lifecycle**: a surface's phases (`phase`, `send(event)`, `moving` / `moved` / `interrupted`), with the stuck-phase watchdog |
| `shell/components/Mutate.qml` | Ability: pill pop and spread enter, own leave, inner reveal cue (task pills, idle circles) |
| `shell/components/ColorWheel.qml` | Hue/saturation wheel and value slider (port of vados-notes `ColorPanel`; swatch and hex field live in `ProfileEditor`) |
| `shell/components/Upright.qml` | Counter-flip transform that keeps text and icons readable inside the mirrored taskbar |
| `shell/components/LabelReveal.qml` | Ability: the V/AS bar-sweep text reveal around its children, a cut for the leave (GitHub name) |
| `shell/components/Squircle.qml` | Superellipse shape (fill and ring) for every profile picture and the best-match circle; `Geometry.superellipse`, `Appearance.radius.squircle` |
| `shell/components/Outline.qml` | Ability: a rounded border that traces itself from the top-left corner both ways to the bottom-right, own fade leave (GitHub history box) |
| `shell/components/Turn.qml` | Flip enter/leave used by every piece that comes and goes |
| `shell/components/{Glyph,GlyphButton,TypedText,Surface}.qml` | Icons (the user's icon set from `utils/Icons.js`, the rest drawn as an SVG path table), icon button, typed text, panel |
| `shell/modules/taskbar/` | Taskbar: `Taskbar` root, `TaskPill`/`TaskItem`, idle pills (`SettingsIdle` above `PowerIdle`), `FoldDot` (compact column bead), `FoldDrag` (idle pointer area, a `Gesture` that folds on crossing), `Carried` drag droplet, `Arrangement`, `TitleTip`; activity pill: `ActivityPill` (body, states, satellites, clicks), `ActivityGlance` (active face per activity), `ActivityBars`, expanded views `ActivityMedia` (disc head, progress ring, controls) and `ActivityCall` (call time, mic and deafen drops) |
| `shell/modules/extension/` | Extension: `Extension` root (the pill grown to full height over the taskbar, own liquid layer, loads a page by key), `NetworkPage` (Wi-Fi header + list), `NetworkRow` |
| `shell/modules/settings/` | Settings: `Settings` root (a `Burst` over the screen; accent main pop bar and white second pop bar; pages), `TabBar` pop bar, `Page` tab page flip, `OptionGroup` labelled choice row, `TextField` labelled text input, `Fader` labelled 0-1 slider; tabs User, Settings, Customization (second `TabBar` on the right), Advanced |
| `shell/modules/search/` | Search: `Search` root (`Burst` column, traced wall `Shape` and its favourites mask, layout, keys), `ResultRow` (list row; `room` shrinks it beside the best match, `fade` under the favourites), `FoundCard` (best match circle and its name pill), `AppTile` (favourite), `AppIcon` |
| `shell/modules/dashboard/` | Dashboard: `Dashboard` root (layout, `Burst` body, content), `Gauge` (generic ring + chip: CPU, GPU with VRAM `Crescent`, RAM), `Ring`, `Crescent` (quarter arc level), name and caption set on the ring with `components/ArcText`, `LevelBar`, `Throughput` (download/upload graph of the last 60 s with ping and jitter, under RAM), `Drive` (disk readout in the bottom step's notch), `Charge` (battery in the far-wall notch, laptops), `Forecast`, `Vacant` placeholder |
| `shell/windows/` | `TaskbarWindow` (taskbar, alerts over its activity pill, extension); `FrameWindow` (frame debugger); `OverlayWindow` (the overlay base: layer, namespace, keyboard, bridges to `Overlays`) and the `SearchWindow`, `SettingsWindow`, `DashboardWindow` built on it |
| `shell/keybinds/Shortcuts.qml` | Hyprland global shortcuts `search`, `settings`, `dashboard`, `activity`, `activityNext`, `activityPrevious` + IPC targets `overlay`, `search`, `settings`, `dashboard`, `desktop`, `activity` (pill: `next`, `previous`, `mode`, `rotate`; bar: `toggle`, `close`, `pin`, `current`), `attention`, `diagnostics` (`report`) and `notifications`; touches `Notifications` and `Attention` at startup so they listen |
| `shell/utils/Fuzzy.js` | Match scoring, frecency, ranking |
| `shell/utils/Log.js` | **The logger**: `info`, `warn`, `error` in one format (`vados: <subsystem>: <message>`), repeats within `repeatWindow` counted instead of printed, the last `capacity` entries in memory (`recent()`); the only file that calls `console.*` |
| `shell/utils/Backoff.js` | Restart delay: `delayOf(failures, Motion.supervision)`, exponential up to a cap |
| `shell/utils/Diagnostics.js` | `report(compositor, overlays, supervisors, entries)`: the plain-text diagnostics report behind IPC `diagnostics report` |
| `shell/utils/Phases.js` | The lifecycle's move table: `next(phase, event, canRecover)` and phase predicates |
| `shell/utils/Geometry.js` | **Geometry**: `clampUnit`, `smooth`, `mix`, `centerOf`, `headingOf`, `splineAt`, `traceSpline`, `refit` (a shape kept in one frame redrawn in another) |
| `shell/utils/Banner.js` | The V/AS ASCII banner (`lines`, `art`) for the settings home page |
| `shell/utils/Icons.js` | **Icon catalogue**: `steps` (which icon a level picks: `speaker`, `wifi`, `battery` with `charging`), `pick(name, level, isCharging)`, `has`, `strokeOf`, `fillOf` |
| `shell/utils/IconPaths.js` | Generated by `tools/icons/build.py`: one 24-unit stroke and fill path per SVG in `tools/icons/source`; never edited by hand |
| `shell/utils/Alerts.js` | Alert source catalogue (Discord, Telegram, WhatsApp, Signal, Slack, Element, Thunderbird, Spotify; `generic` otherwise): `identify(appName, desktopEntry)`, `plainOf`, `clip`, `leadOf` |
| `shell/modules/alerts/Alerts.qml` | Alerts: the content of an alert (source badge, label, summary, typed body) over the activity pill's body, swipe to dismiss and tap to open (`Gesture`); hosted by `TaskbarWindow` |
| `shell/utils/Lock.js` | Lock screen module catalogue and 16 x 16 grid placement (`parse`, `fits`, `place`, `remove`, `isPlaced`) |
| `shell/modules/settings/Piece.qml`, `LockEditor.qml`, `ProfileEditor.qml` | `Piece`: one settings element with its own staggered enter (`Page` arranges them); `LockEditor`: the lock screen grid editor; `ProfileEditor`: the Profile tab laid out from the user's mockup |
| `shell/utils/Schema.js` | **Configuration schema**: every `shell.json` key with its type, default and allowed values (`settings`), `version`, `migrations`, `findProblem`, `createDefaults`, `migrate`, `validate`, `repair` |
| `shell/utils/Platform.js` | **Compositor capability contract**: one row per backend answering every capability (`activeWindow`, `windowGeometry`, `fullscreenDetection`, `focusTracking`, `windowControl`, `windowMinimize`, `windowSnap`, `workspaceManagement`, `freeCanvas`, `layerShell`) and the support level (`core`, `extended`, `native`); the README "Compositor support" table mirrors it |
| `shell/utils/Liquid.js` | **The liquid engine**: springs from a character (`rise`, `ring`, `arrival`, `pull`) and the neck's merge and separation (`isMerged`, `neckKick`) |
| `shell/modules/{canvas,clipboard,lock,notifications,widgets}/` | Empty, planned: each is a row with `isBuilt: false` in `utils/Features.js` and a contract in `roadmap.md` |
| `shelf/dashboard-wave/` | Shelved: the dashboard's pour-out wave with idle ripple (`Wave.qml`, the old `Dashboard.qml`, `README.md` with its tokens); not loaded |
| `tools/preview/` | Windows playground: `play.py` builds a mock `qs.*` tree (real config, components, state and modules; mocked `Config`, services) and runs `play.qml` in-process with taskbar, search, settings and dashboard together (`D` / `Ctrl+D`); `Num 0` holds and `Num +` copies a screenshot to the clipboard from anywhere, the search field included |
| `.claude/docs/interfaces.md` | Per layer: owner, allowed imports, public interface, callers; component-level token groups; which feature asks which capability |
| `.claude/hooks/docs-current.py` | Stop hook that keeps these docs current |
| `tools/check-rules.py` | Hard-rule checker (Stop hook and CLI): compositor boundary and capabilities (README table = `Platform.js`), layer imports and component tokens (`[layers]`), shared geometry, surface lifecycles, module imports, liquid physics, paced durations, tokens, overlays, gestures, attention, state, network list, lock, mocks, engine tests, the feature registry against the tree (`[features]`), settings rows |
| `tools/tests/` | Qt Quick tests (`run.py`, `tst_*.qml`, `fakes/` for Quickshell `Singleton`, `Scope`, `Quickshell`, `FileView`, `Process`; `run.py` also gives tests `VadosTest.Disk` and a high-resolution `VadosTest.Clock`). `tst_budget.qml` measures the search burst's script time per frame against `Motion.budget`; `tst_rendering.qml` checks which liquid passes run under full, lite and unshown; `tst_platform.qml` checks the capability contract and Desktop mode's degrade path; `tst_features.qml` checks the feature registry and measures the ready time of `Burst`, `Mutate` and the alert's `Reshape` against `Motion.budget.ready`; `tst_alerts.qml` checks the alert source catalogue; `tst_preview.qml` also posts a notification and checks that it peeks out of the activity pill, that a tap opens it and a swipe dismisses it |

Where to change things:

- A new surface, or building a planned one: its row in `utils/Features.js`, then the steps in `architecture.md` § Features; its contract is in `roadmap.md`.
- A new module inside a surface (lock module, settings tab, activity): the surface's catalogue row and one file in its folder (`rules/features.md`).
- How fast a surface must show its first content: `Motion.budget.ready`, by impact.
- When the taskbar hides: `Occupancy.qml` (the rule) and `Compositor.qml` (the geometry).
- Any speed: `Motion.qml`.
- How a surface enters, leaves or recovers from an interruption: its `Lifecycle` handlers (`Burst`); the allowed moves in `utils/Phases.js`.
- What a compositor can do: `utils/Platform.js` and the README "Compositor support" table, together.
- A setting in `shell.json`: its entry in `utils/Schema.js`, the adapter property and a setter in `Config.qml`, a README row (`check-rules.py` keeps the three in step); a changed layout bumps `Schema.version` with a step in `migrations`.
- How anything liquid bounces, wobbles or settles: its character in `Motion.liquid`; the maths in `utils/Liquid.js`.
- Adding a WM: a backend branch in `Compositor.qml` only.
- A process or fetch that must keep working: a `Supervisor` beside it; restart timing in `Motion.supervision`; what the shell says in `Log` calls.
