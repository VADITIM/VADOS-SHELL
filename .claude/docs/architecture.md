# Architecture

Layers: `config → services → components → modules → windows → shell.qml`, plus `state/` (sideways) and `keybinds/` (state flips). Rules in `rules/architecture.md`. The product direction and its phases are `direction.md` (user, 2026-11-07).

## Engine map

How the subsystems of `direction.md` land in this tree:

| Direction | Here |
|---|---|
| Experience layer | `modules/` (taskbar, search, dashboard, settings), hosted by `windows/` |
| Liquid interaction engine: orchestration, interruption | `components/Lifecycle.qml` + `utils/Phases.js` (transition phases), `state/Overlays.qml` (which surface is up), `components/Gesture.qml` (gestures and velocity) |
| Motion system | `config/Motion.qml` (tokens, `pace`), `utils/Liquid.js` (springs) |
| Geometry system | `utils/Geometry.js` (clamps, easing, mixing, splines), `Compositor.toScreen` (backend to screen coordinates) |
| State machine | `Lifecycle` per surface; `Overlays` for surfaces against each other; `Attention` for interruptions by notifications |
| Rendering system | `components/LiquidLayer.qml` and the liquid primitives (`LiquidShape`, `LiquidBridge`, `EdgeFuse`, `Lobe`) |
| Platform adapters | `services/Compositor.qml` with `capabilities` and `level` (`utils/Platform.js`) |
| System services | `services/` |

## Transition lifecycle

`components/Lifecycle.qml` runs one surface's phases: `idle → preparing → entering → active → exiting → idle`, with `recovering` for a reopen during the leave. The moves are a pure table in `utils/Phases.js` (`next(phase, event, canRecover)`); an event a phase does not accept changes nothing, so rapid or out-of-order input can never reach an invalid phase.

- The host sends `show` and `hide` (from `isShown`) and its animations send `prepared`, `entered`, `recovered` and `exited` from a final `ScriptAction`, so an animation that was stopped never reports.
- `show` during `exiting` is an interruption (`interrupted`): it goes to `recovering` when the host can rewind (`canRecover`), else back to `preparing`.
- `moving(from, to, event)` fires before the phase changes (the host captures its leave form there, while it still reads the old phase); `moved` fires after it (the host starts animations there).
- **Recovery**: a watchdog (`Motion.lifecycle.stuck`, longer than any real phase) runs only while a phase is moving. If it fires it logs `vados: <name> stuck in <phase>` and sends `settle`: entering phases land on `active`, `exiting` on `idle`, and the host snaps its values to that end. No surface can stay orphaned half-open.
- Hosts: `Burst` (dashboard, search; recovers by rewinding) and `Launch` (settings; restarts). Their `isActive`, `isLeaving` and `phase` read the lifecycle.

## Compositor boundary

`Compositor` picks a backend once:

1. **hyprland**, when `HYPRLAND_INSTANCE_SIGNATURE` is set. It runs `hyprctl -j monitors` and `activewindow`, 60 ms after relevant socket2 events and every 2 s.
2. Otherwise it starts `driftwm msg --json subscribe`. The first `State` line selects **driftwm**. Each line is a full snapshot (camera, zoom, windows, outputs, fullscreen, pinned). The stream restarts 2 s after it exits.
3. **generic**, when the stream fails. It reads `ToplevelManager.activeToplevel` and counts as covered only when fullscreen or maximized.

It publishes:

- `activeWindow`, screen-local and Y-down
- `focusedScreen`
- the raw `canvasState`
- `viewports()`
- the `canvasChanged` signal

Writes go out through `send([...])` / `action("spec")` as detached `driftwm msg` calls.

**Capabilities** (`utils/Platform.js`): features ask `Compositor.capabilities` (`activeWindow`, `windowGeometry`, `windowControl`, `freeCanvas`, `workspaces`, `layerShell`) and never which compositor runs. `Compositor.level` is `core` (generic), `extended` (Hyprland: geometry, no window control) or `native` (driftwm: free canvas and control, so Desktop mode). `Confinement.canConfine` is `freeCanvas && windowControl`.

## Taskbar hiding

`TaskbarWindow.isCovered = Occupancy.isCovered(screen)`, and `Taskbar.isRevealed = !isCovered || isSummoned`. Dwelling on or pulling the 3 px edge strip summons the bar (`EdgePull` ability: dwell and pull drive the bead, `summoned()` calls `Taskbar.summon`).

## Taskbar side

`Config.data.taskbar.side` anchors `TaskbarWindow` to the left or right edge. The `Taskbar` module is always laid out for the left edge. On the right, `isMirrored` flips the whole module with an `Upright` scale of -1 around its centre, and every readable leaf flips back with its own `Upright`: task icons, idle glyphs, idle expansions, the clock, the title tip text and the carried icon. Pointer coordinates and `mapToItem` go through the transform, so carry and neck logic is unchanged.

**Compact idle column**: every idle circle's pointer area is a `FoldDrag` (`modules/taskbar/FoldDrag.qml`), a `Gesture` that calls `Taskbar.foldIdles(isFolding)` once a press travels `Motion.fold.threshold` up or down, and swallows the click that follows. Down folds, up unfolds. `foldIdles` closes any open idle and emits `compactRequested`; `TaskbarWindow` writes `taskbar.compact` to `shell.json` and feeds it back as `Taskbar.isCompact`. While compact, only idles with `isKeptCompact` (audio, power) stay `isPresent`; the others close their slot (`room`) and pop out, and `FoldDot` (a small liquid bead with three specks, top of the column) pops in. A click on it, or a drag up on it or any idle, unfolds. The compact column is the seed of the activity bar (`roadmap.md`). The input mask lives in the window (`inputZone`, placed from `Taskbar.inputWidth`), not in the transformed module. `Occupancy` checks the edge the taskbar is on.

## Overlays absorb the taskbar

Search, settings and the dashboard sit on the overlay layer, above the taskbar, so their liquid can only react to the taskbar if they draw it themselves. `Overlays.open` calls `gatherTaskbar(screen)`: unless the taskbar on that screen is already away, it emits `taskbarGathering(screen)` and adds the screen to `awayScreens`. On that signal `TaskbarWindow` publishes `Taskbar.liquidParts()` (every shown pill body and idle circle except the gear, none for `bare`) with `placeTaskbarParts`, and the gear circle with `placeSettingsOrigin`.

Both are in **edge-relative coordinates**: the taskbar's own left-edge layout, before mirroring, which equals the distance from the screen edge. Each overlay mirrors them itself from the live `taskbar.side`, so geometry never depends on when the layer-shell window re-anchors.

While away the taskbar is cut to opacity 0 and unrevealed, and the overlay's `Gather` (`components/Gather.qml`) draws the same silhouettes in its own `LiquidLayer` and pulls them into one point, where they goo into the overlay's body. The overlay emits `landed()` at the end of its leave; `Overlays.returnTaskbar(screen)` then brings the taskbar back unless another overlay is open on that screen.

- **Settings**: parts gather into the gear, then the ball flies to the centre.
- **Dashboard and search**: `Burst` streams the parts to the taskbar column, where they form a new ball fused to the screen edge, which explodes along the overlay away from the edge.

## Abilities

Animations are **ability components**: attached to an element, an ability watches the element's state and plays its own motion; the host sets state and binds to the ability's cues, never runs a timeline. One ability, one concern:

| Ability | State it plays | Use |
|---|---|---|
| `Turn` | enter, leave (`isShown`) | wraps a piece that comes and goes |
| `TypedText` | enter, leave, text change | text arriving on screen |
| `Press` | click (`isPressed`), hover or selection (`isRaised`) | `Press { target: item; isPressed: area.pressed }`, animates the target's `scale` |
| `Jolt` | haptic (`kick()`, `settle()`) | keyframed bounce `value` from `steps` tokens: the settings tab switch |
| `Mutate` | enter, leave (`isShown`) | pill pop, spread and inner reveal cue (`isInnerShown`), `departed()`; task pills spread, idle circles only pop (`hasSpread: false`); the taskbar enter is their staggered `Mutate`s. Task icons enter from the centre outwards: `isInnerShown` fires halfway through the spread, the centre icon turns in then, and each ring further out is deferred (`TaskItem.openingDelay`) so the outermost starts once the spread is full (`Mutate.spreadAfterInner`, at least `Motion.pill.elementStagger` per ring); icons added to an open pill enter at once |
| `EdgePull` | hover dwell, drag pull | the hidden taskbar's edge strip and bead; `summoned()` |
| `Rising` | idle (`isRunning`) | bubbles off an open body |
| `Gather` | absorb (`merge`) | taskbar silhouettes pulled into one point (inside `Launch`) |
| `Launch` | enter, leave (`isShown`) | the settings body: merge into the gear, flight, pop, tab bar bud; cues `isOpened`, `isBudOut`, `hasMerged`, `landed()` |
| `Burst` | enter, leave (`isShown`) | the dashboard and search body born from the taskbar parts at the taskbar column, its root side a `Lobe` into the screen edge, bouncing out into its form; publishes `visitor` while leaving; cues `isOpened`, `isActive`, `form`, `landed()` |

Abilities without visuals are `QtObject`s (`Press`, `Mutate`, `Jolt`), so attaching one never takes a slot in a `Row` or `Column`. A `Behavior` easing a property towards a state value (overlay dim, idle stretch, hover swell, taskbar inset and fuse) counts as an ability. Not yet an ability: the taskbar carry (drag) choreography in `Taskbar.qml`, whose droplet is `Carried`; right click has no animation.

## Liquid engine

One physical identity for everything liquid (user, 2026-11-06). Three parts, no feature has its own physics:

- **Material**: `LiquidLayer` (blur `melt` per surface, then the `Appearance.liquid` thresholds) is the only goo. Bodies are `LiquidShape`, `LiquidBridge`, `Lobe`, `EdgeFuse` and `Shape`s inside a layer.
- **Characters**: every spring, bounce and wobble is a named character in `Motion.liquid`, written the V/AS way (`components/29-physics-motion.md`), so a spring tuned here feels the same as one in VAD/OS Notes:
  - `response`: seconds of one undamped swing. Mass and elasticity in one number: heavier or softer is a longer response.
  - `damping`: damping fraction, below 1 (liquid always overshoots; `quirks.md`).
  - `expansion`: the launch speed, in swing amplitudes. A rise with 0 starts from rest; a ring's amplitude is its expansion.
  - Settling is derived from the two above (the envelope is `e^(−damping · 2π / response · t)`), never set on its own.
- **Maths** (`utils/Liquid.js`, pure functions on a character):
  - `rise(character, seconds)`: 0 → 1 with overshoot and settle; enters and bounces.
  - `ring(character, seconds)`: a wobble around rest after a kick; impacts and pops.
  - `arrival(character)`: seconds until a rise first reaches 1; choreography keys off it (the burst's wave start).
  - `pull(value, velocity, target, character, frameTime, Motion.liquid)`: one frame of the semi-implicit spring integrator (1/240 s substeps, 50 ms cap) for anything a finger drives.
  - `isMerged(wasMerged, closeness, neck)` and `neckKick`: the neck between two bodies merges past `neck.merge`, separates under `neck.separate`, and kicks the droplet by `mergeKick` / `separateKick`.

| Character | Plays | Was |
|---|---|---|
| `burst` | `Burst` width and height bounce | `bounceDamping`, `bounceCycles` |
| `crash` | `Burst` far-wall impact wobble | `impactDamping`, `impactCycles` |
| `launch` | `Launch` panel pop wobble | `wave`, `waveDecay`, `waveCycles` |
| `pill` | `Mutate` pop of task pills (60 ms) | `Easing.OutBack` |
| `circle` | `Mutate` pop of idle circles and the fold dot (220 ms) | `Easing.OutBack` |
| `follow`, `dock` | `Carried` droplet following the finger, docking into its slot | `Motion.springs` |
| `droplet` | `Carried` stretch | `Motion.springs.wobble` |
| `neck` | taskbar carry neck merge and separation | `carry.joinShare`, `snapShare`, `joinKick`, `snapKick` |

Closed-form rises and rings run on an ability's own clock (a linear phase in seconds), so they stay abilities; `pull` runs in a `FrameAnimation`. Leaves are not springs: they keep their own faster easing (`Mutate` InBack), as the animation rules require. A new liquid surface (alerts, clipboard, lock) picks a character or adds one; it never writes `Math.exp` itself.

## Activity and notifications

`state/Activity.qml` is the shared state of the activity bar (roadmap 1), the sideways channel its pieces will read: `openScreen`, `pinnedKind`, `entries` merged from services (`notifications` from `Notifications`, `tray` from `Tray`; each `{ kind, count, unread, isUrgent, latest }`), and `current`: the pinned entry, else the first urgent, else the first unread, else the first. `open(screen)` marks notifications read. Media and calls will join `entries` as services for them land.

`services/Notifications.qml` owns `org.freedesktop.Notifications` through a `NotificationServer` inside a `LazyLoader`, active only while `notifications.enabled` (default off, `decisions.md`). Every arriving notification is tracked and unread until `markRead`; `list` is newest first. `Shortcuts` binds to `Notifications.isServing`, which creates the singleton at startup (`quirks.md`).

Entry points before the bar exists: the Hyprland shortcut `vados:activity`, IPC `activity toggle | close | pin <kind> | current` and `notifications enable | disable | status | count | clear`.

## Overlay engine

`state/Overlays.qml` is the one registry for full-screen surfaces (it replaced `Visibilities`, 2026-11-07). `kinds` declares each overlay and its `layer` (search, settings and dashboard share layer 1). State: `screens` (key → screen), `stack` (opening order; `top` is the last), `awayScreens` (screens whose taskbar is gathered), `taskbarParts`, `settingsOrigins`, `visitors` (screen → overlay → leaving ball).

- `open(key, screen)` closes every overlay on the same layer or below, gathers the taskbar (once per screen: a switch keeps the first gather's parts), and pushes the key on the stack. `close`, `toggle`, `closeTop` (Escape, IPC `overlay close`).
- `ownsKeyboard(key, screen)`: only the top overlay takes exclusive keyboard focus.
- `returnTaskbar(screen)` (an overlay's `landed()`) brings that screen's taskbar back only when no overlay is left on it, whichever screen the next overlay opened on.
- `placeVisitor(key, screen, ball)` / `visitorOn(screen)`: each leaving overlay owns its own entry, so one leaving never erases the other's ball.

`windows/OverlayWindow.qml` is the window side: a full-screen `PanelWindow` on the overlay layer, namespace `vados-<key>`, keyboard from `ownsKeyboard`, with `isOpen`, `parts`, `requestClose()`, `land()` and `placeVisitor()` for its module. `SearchWindow`, `SettingsWindow` and `DashboardWindow` are an `OverlayWindow` plus their module. A new overlay is a `kinds` entry and an `OverlayWindow`.

## Gesture engine

`components/Gesture.qml` is a `MouseArea` ability for every drag: `threshold` (default `Motion.gesture.slop`), axes, `dragButtons`; it tracks `travelX/Y` from `pressPoint` and a smoothed velocity (`Motion.gesture.velocityBlend`). Signals: `moved` every move, `crossed` once when the travel passes the threshold, `thrown(travel, velocity)` on release after a drag, `tapped(mouse)` on a release without a drag, `ended` always. Built on it: `FoldDrag` (fold on crossing), `EdgePull` (pull length on `moved`, summon on `crossed`), the task carry in `Taskbar` (`crossed` picks up, `moved` carries, `thrown` lands, `tapped` activates or closes). Named `Gesture` because `Drag` is QtQuick's attached type and wins inside `qs.components` (`quirks.md`).

## Attention engine

`state/Attention.qml` decides whether a notification may interrupt (`rules/interaction.md`). It listens to `Notifications.received`; `mayPeek` lets critical through always, holds low always, and holds normal ones under do-not-disturb (`attention.doNotDisturb`) or while the active window is fullscreen. Admitted notifications gather for `Motion.attention.batch` and then become one `peek` `{ notifications, isUrgent, screen }` on the focused screen, which expires after the longest own timeout (`expireTimeout`, seconds) or `Motion.attention.peek`; urgent peeks stay until dismissed, and a peek drops notifications as they are dismissed. The alert band will draw `peek`; held notifications are still counted by `Activity`.

## Persistence

`services/StateFile.qml` is a reusable `Scope` for runtime state: `name` → `~/.cache/vados/<name>.json` as `{ version, data }`, `values` (defaults merged with the file), `update(next)` (debounced `Motion.store.write`), `flush()` (also on destruction), `isLoaded`. A file without `version` is read as plain data; a file that does not parse is copied to `.corrupt`, another version to `.version<N>`, and the defaults are used. Users: `Apps` (launch history, still `apps.json`), `Confinement` (`desktop.json`: parked windows).

`Confinement` waits for `isReady` (state loaded and a driftwm canvas seen) before `recover()`: saved parked windows that still exist are adopted in Desktop mode (so `enter()` never parks them a second time at their parking spot), or put back in Canvas mode; windows that no longer exist are dropped. Every park and restore is saved.

## Reduced motion

`Motion.isReduced` (`motion.reduced`, settings System tab) and `Motion.pace(duration)`, the single precedence function: every duration in components and modules goes through it and is 0 under reduced motion. `Rising` stops emitting (`isEmitting`) and `Burst` has no splashes or crests. `TypedText` and finger-driven motion are content and keep their timing; `Motion.reveal.dwell` is an interaction timer, not motion.

## Interruptions

Surfaces go through their `Lifecycle` (§ Transition lifecycle). `Mutate` re-enters from its current pop (`holdPop`). `Burst` reopened during its leave, before the hand-off (`canRewind`), rewinds the leave (`rewinding`, exit back to 0 over the time already spent) and resumes the enter from the spread and impact it had reached (`resuming`), instead of converging from an empty ball again.

## Settings

`SettingsWindow` is a full-screen overlay layer per screen (namespace `vados-settings`, exclusive keyboard while open), like search. It bridges `Config` into `modules/settings/Settings.qml` and its signals back to `Config.setAccent`, `setTaskbarSide`, `setTaskbarStyle` and `setWindowMode`.

Opening: the gear (`SettingsIdle` → `settingsRequested` → `TaskbarWindow`) or `CTRL + P` (`GlobalShortcut` / IPC `settings toggle`, focused screen) calls `Overlays.toggle("settings", screen)`, which also closes search and the dashboard.

Morph (the `Launch` ability, playing from `isOpen`: linear phase values; `enterForm`, `trailForm` and `splashForm` turn them into shapes in one `LiquidLayer`; the taskbar parts are a `Gather` inside it; `Settings` only binds `isContentShown` and the tab bar to `launch.isOpened` and `launch.isBudOut`):

1. **Merge**: every taskbar part is drawn into the gear pill, near ends first (`mergeLag`), while the gear swells into one ball (`Appearance.settings.ball`).
2. **Shoot**: from the gear, the ball crouches away from the panel (squash), then fires straight to the panel centre, stretched by speed with three trailing droplets that catch up.
3. **Pop**: impact squash and inflate along the flight line, then the bubble bursts open into the panel. Width and height wobble in antiphase (the `launch` character, `Liquid.ring`), and splash droplets ride just ahead of the wave front and settle back into the edge. Content `Turn`s in at `contentShare`, and `Rising` bubbles start leaving the top and bottom edges for the screen edges.
4. **Tab bar**: a circle buds out of the container's left edge (OutBack), then extends into the `TabBar` pill, and its items enter.

Tab switch: the highlight slides, the panel jolts (`Jolt` haptic, fed into `Launch.jolt`), the old page leaves (`Motion.settings.pageSwap`) before the new one enters. Close (its own animation): content out, bubbles drain, the tab bar retracts into the panel, the panel implodes into the ball (InBack) from wherever it was, the ball is sucked back to the gear (InCubic, stretched), then `landed()` → `Overlays.returnTaskbar` lets the taskbar re-enter with its own pill pop while the ball shrinks into the gear. The gear is mirrored by the live `taskbarSide`, so a side switch from the settings sends the ball to the new side.

`Appearance.color.accent` reads `Config.data.appearance.accent`, so every accent in the shell recolours live. `setAccent` updates the adapter at once and writes `shell.json` `Motion.settings.write` ms after the last change, so a wheel drag does not write every frame.

## Desktop mode (driftwm)

`Config.desktop.mode` drives `Confinement.isConfined`.

- **Enter**: record the home camera, set zoom 1, park every non-focused movable window.
- **Every canvas change**, after a `Motion.desktop.settle` debounce:
  - snap the camera back home;
  - restore a parked window that got focus;
  - cascade unknown windows into view;
  - clamp known windows back inside.
- **Leave**: restore all parked windows.

Taskbar clicks go through `Toplevels.activate` to `Confinement.activate`, which restores, focuses or minimizes.

## Dashboard

`DashboardWindow` is a full-screen overlay layer per screen (namespace `vados-dashboard`, exclusive keyboard while open). It opens from a click on the taskbar clock (`Taskbar.dashboardRequested`), the Hyprland shortcut `vados:dashboard` or IPC `dashboard toggle`, all through `Overlays.toggle("dashboard")`. Search, settings and dashboard are mutually exclusive.

Data: two `Binding`s set `Hardware.isActive` and `Weather.isActive` while the window is open, so hardware polling (`Motion.dashboard.poll`) and the weather fetch (only when older than `weatherPoll`) run only then.

Liquid: one `LiquidLayer` over the whole screen. Inside it one `Upright`-mirrored item holds the `Burst` ability (the body and every drop of its enter and leave) and `Rising`, laid out for the left edge. The body keeps `rootCorner` on the taskbar side and `corner` on the front. Content is placed with `placeX`, which mirrors whole columns so the processor column always sits nearest the taskbar. The dashboard drives no timeline itself: `Burst` plays from `isShown`, content shows on `burst.isOpened`, bubbles run on the same flag, dim is a `Behavior`.

Enter (`components/Burst.qml`, about 0.8 s):

1. **Converge** (`converge`, InQuad): every taskbar part tips over towards the seed point (the taskbar column, `seedX`, at the dashboard's height), contracts into a stream and flies in, nearest first (`convergeLag`). The ball bulges out of the screen edge. There is no ball before: the ball is only the mass that has arrived (`ball · √arrived`), so it is born from the parts.
2. **Charge**: the ball inflates and squashes (`impactShare`, `inflate`, `squash`).
3. **Bounce out** (`spread`): width and height follow the `burst` character (`Liquid.rise`, launched at `expansion` so it is `1 − e^(−σt)·cos(ωt)`), over the spread's seconds. The height leads (`heightLead`), so the body first stands up between the top and bottom walls, then shoots out along the dashboard, overshoots the far wall by about 15 % and snaps back, stretched thinner while overshooting (`drag`). The root side settles onto the root wall early (`rootShare`).
4. **Waves crash**: when the height first reaches its walls one wave per side (a single `Shape` bump, `crestLength` long, drawn along the wall path by `wallPoint`) starts at the root on the top and bottom walls, runs along it, wraps round the far corner curve and meets the other on the far wall at 50% height (`crestRun`). The meeting starts `impact` (its own timeline, paused until `meetShare` of the spread): the two halves fuse into one mound that swells and sinks into the body, a jet droplet leaps off the far wall and falls back, and the body bounces like a puddle hit by a drop (far wall dents in then out, height the other way, damped: `impactPush`, `impactCycles`, `impactDamping`). A droplet also splashes off each far corner (`splashSpan`).
5. **Steps**: two rectangles in the liquid give the body a step: the top from the root to `stepTopShare` of the width rises `stepTop` above it, the bottom from the root to `stepBottomShare` drops a bigger `stepBottom` below it. Both scale with the body height, so they grow in and shrink away with it. While they show (`isStepped`), the root `Lobe` grows by their rises (`aboveRise`, `belowRise`) and shifts its centre, so the edge curve covers the steps too. With `hasSideStep` (the host sets it when `Battery.isPresent`), a third step (`stepForm("side")`) grows out of the far wall, `stepSide` deep and `stepSideHeight` tall, centred `stepSideOffset` below the middle, from the moment the waves meet until the overshoot ends (`spread` from `meetShare` to 1), so it lands with the body's bounce. It rides the impact wobble with the wall. A fan of spray droplets runs ahead of the front and is swallowed when it catches up.
5. Content `Turn`s in by distance from the root (`Motion.dashboard.reveal` ms per px) once `openShare` of the spread has passed; `Rising` bubbles leave the top and bottom surfaces.

**Root fused to the edge**: the whole root side is a `Lobe` (the search lobe shape) from past the screen edge (`edgePad`) to `rootSpan` inside the body, flaring wider at the edge by `rootSwell` (scaled by `swellShare` while small), so the dashboard curves into the screen edge the way the search band does. It follows the body through enter and leave. The crest track starts at the screen edge and runs over this flare (`Lobe.bendAt`, sampled `curveSamples` times) before the top and bottom edges, so the wave covers the curves at the screen edge too (dashboard and search).

Leave (own, faster): content out, bubbles drain, a short hold, then `landed()` → `Overlays.returnTaskbar`, so the taskbar pops back in on the same timeline while the body leaves in one motion (`exit`, linear over `Motion.burst.leave`): it scales down towards the `leaveBall` circle with its root side kept on the screen edge (OutCubic, done at `Motion.burst.leaveShrink`), and at the same time slides out past the edge (quadratic travel), so it never stops at the edge and never pulls towards its centre.

**Touching the taskbar on leave**: while leaving, `Burst.visitor` (`{ x, y, width, height, isHandedOff }`, left-edge coordinates) goes `Dashboard.visitor` → the window → `Overlays.placeVisitor` → `TaskbarWindow` → `Taskbar.visitor`. `Taskbar.touchOf(centerX, top, bottom, halfWidth)` gives each task pill and idle circle a 0–1 closeness to it (within `Appearance.taskbar.visitReach`), which swells the pill by up to `visitSwell`. Once it has become the ball (`exit >= leaveShrink`) it is handed off (`canHandOff`, off for the `bare` style, whose liquid is invisible): `Burst` stops drawing it and the taskbar draws the same ball and edge lobe in its own `LiquidLayer`, so it goos and necks with the pills it passes. The windows are separate layers, so a shape can only fuse with the pills inside the taskbar's own layer.

With no parts (another overlay was open first) the ball grows from nothing on `merge` alone.

The earlier wave enter (a travelling `PathPolyline` ripple, crest bulge, idle ripple while open) is shelved in `shelf/dashboard-wave/` for later use.

Readings:

- `Gauge`: temperature `Ring` (dashed track, solid arc in the temperature band colour, red zero tick, white knob at the value) around the chip glyph, with the load percentage in the chip's centre; glyph and percentage take the usage band colour. The temperature reading sits directly under the name (`caption`). GPU, CPU and RAM sit in a triangle (GPU top left, CPU top right, RAM centred below). The GPU gauge has a VRAM `Crescent` (a quarter-circle arc, `arcStart` 180° and `arcSweep` 90°, `arcGap` outside the ring at its top left, filling from the 9 o'clock end upwards) with the used/total GB under its start (`hasBar`); the CPU has none. CPU and GPU glyphs differ only by their pins: lines (CPU) or blocks (GPU).
- RAM is a third `Gauge`: the `ram` chip glyph with "RAM" in its centre, the ring tracking used/total in usage colours, `16GB/32GB` under it. `Gauge` is generic (ring share and colour, glyph colour, centre text, caption); `Dashboard` computes the values.
- `Drive`: the disk readout (glyph, mount, page dots, used/total GB, horizontal `LevelBar`) lives in the bottom step's notch below the body, inside its own clip (`notchClip`, following `Burst.bottomStep`) so it grows and leaves with the step. A tap on the glyph pages through `Hardware.disks`.
- `Charge`: on laptops, a vertical battery (outlined body, cap, fill rising from the bottom, a bolt while charging) and the percentage in the far-wall notch (`sideClip`, following `Burst.sideStep`). Six colours by level (`battery.bands` 10/25/40/60/80%): critical, hot, warm, fair, full, cool. It reveals once the notch is half out.
- Colours are bands from `Appearance.bandColor`: usage `[0.75, 0.85, 0.95]`, temperature `[60, 70, 85]` °C → cool, warm, hot, critical.

## Search

`SearchWindow` (overlay layer, exclusive keyboard) hosts the `Search` module. Search is built on the dashboard's foundation: the same `Burst` ability inside an `Upright`-mirrored item, the same `bodyClip` content clip, the same leave and taskbar hand-off (`visitor` → `Overlays.placeVisitor` (keyed by overlay, read back with `visitorOn(screen)`), `canHandOff` off for `bare`). The `Burst` form is the base column: `Appearance.search.widthShare` (20 %) of the screen wide, the full screen height, `hasSteps: false`, `rootCorner` on the taskbar side, seeded at the taskbar column at mid-height.

The far wall (from the user's second sketch, 2026-11-06) is part of the `Burst` body: Search passes `wall` (points traced from the drawing, `Appearance.search.wall`, converted to `[x offset from the full far edge, y share]`) and `Burst` draws it in its own liquid. Each point sits at `formRight + offset × wallShare`, `formTop + share × form.height`, so the wall grows, squeezes and bounces with the body every frame. `wallShare` is the body's width progress after the impact (it overshoots with the bounce) and collapses with the leave. `Burst.traceSpline()` turns the points into one Catmull-Rom outline (`wallOutline`, `Appearance.burst.curveSamples` per segment), so the wall is a single S-wave: in past the favourites, out round the best match, in again near the bottom, flaring at both screen edges. The fill starts `form.right` inside the column edge, so the body's corner never shows a notch.

A walled body is one polygon (`bodyOutline`) traced along the top and bottom tracks (`topTrack`, `bottomTrack`, shared with the crest; all three, and `crests`, are written by `trace()`, queued once per frame with `Qt.callLater`), with the wave's troughs cut into it beside the crest; its wall ends curve inward until `flare` turns them outward into the screen edges after the bounce; Search's mask top and bottom (`maskTop`, `maskBottom`) follow them. With a wall, the burst's crest runs along `wallOutline` instead of the plain far side, the jet leaves from the wall at mid-height (`farFront`) and the corner splashes leave from the wall's ends. Search reads `burst.wallOutline` for `wallReach` and the favourites mask; the click bands (`wallBands`, one `MouseArea` each) come from the settled wall (`settledWall`), so the `Repeater` is not rebuilt every frame; `presence` (`bud` × `wallShare`) only drives content (row shortening).

Content, placed with `edgeX` (mirrors to the right edge):

- **Favourites** (`AppTile`): a grid filling row by row, `favoriteColumns` across (more columns once there are more than `favoriteColumns × favoriteRows`) and `favoriteRows` down, at the top from the list's left edge. It sits in a horizontal `Flickable` (scroll or drag); tiles leaving the taskbar side fade over one cell. The strip is masked by `wallMask` (the same wall path from the screen edge, through a `MultiEffect` mask), so tiles are cut by the curved wall, as drawn.
- **List** (`ResultRow`, in `bodyClip`): every result after the best match, from the top to the field, resting `listLead` below the top so it starts under the favourites. Rows scrolled up into the favourites band fade (`fade`), shrink by `rowShrink` and lose their name first, leaving faint icons under the first favourite column. Rows beside the best match get a `room` from `Search.rowRoom(rowTop)` that ends `lobeGap` before its circle, so the name elides at the end; that part has no fade.
- **Best match** (`FoundCard`): a circle (`found`, wash fill, `ringStroke` ring, accent while selected) with the icon (`foundIcon`) inside, at `foundX` from the root and `foundShare` of the height. Its name is in a liquid pill outside the wall (`nameReach` past the wall's widest point), joined to the circle by a `tether` line. The pill is a `LiquidShape` in Search's liquid layer sized from `FoundCard.nameSpan` / `nameThickness`, so it necks with the wall; `FoundCard.bloom` (a `Behavior`, OutBack in over `Motion.search.nameGrow`, InQuad out over `nameShrink`) grows it from a droplet at the wall side to the far side, its height opening from the vertical middle first (`nameHeightLead`), and the name is revealed by the clip.
- **Field**: the wash pill at the bottom of the column, with the result count and the search glyph on its right.

Content `Turn`s in by distance from the root (`Motion.search.ripple` ms per px, plus a row stagger); while typing, new rows use only `settledStagger`.

Keys: arrows move inside a zone. From the best match, toward the taskbar or down goes to the list and up goes to the favourites. From the list, away from the taskbar goes to the best match and up from the first row goes to the favourites. From the favourites' bottom row, down goes to the list. Directions mirror with the side. Tab and Shift+Tab cycle the zones; Enter launches; Escape clears the query, then closes.
