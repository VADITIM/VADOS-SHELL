# Architecture

Layers: `config → services → components → modules → windows → shell.qml`, plus `state/` (sideways) and `keybinds/` (state flips). Rules in `rules/architecture.md`; each layer's owner, imports, public interface and callers in `interfaces.md`. The product direction and its phases are `direction.md` (user, 2026-11-07).

## Engine map

How the subsystems of `direction.md` land in this tree:

| Direction | Here |
|---|---|
| Experience layer | `modules/` (taskbar, search, dashboard, settings), hosted by `windows/` |
| Liquid interaction engine: orchestration, interruption | `components/Lifecycle.qml` + `utils/Phases.js` (transition phases), `state/Overlays.qml` (which surface is up), `components/Gesture.qml` (gestures and velocity) |
| Motion system | `config/Motion.qml` (tokens, `pace`), `utils/Liquid.js` (springs) |
| Geometry system | `utils/Geometry.js` (clamps, easing, mixing, splines), `Compositor.toScreen` (backend to screen coordinates) |
| State machine | `Lifecycle` per surface; `Overlays` for surfaces against each other; `Attention` for interruptions by notifications |
| Rendering system | `components/LiquidLayer.qml` (goo) and `components/Masked.qml` (masks), the only owners of effects and layers; `config/Rendering.qml` (quality, `blur`); the liquid primitives (`LiquidShape`, `LiquidBridge`, `EdgeFuse`, `Lobe`) are plain shapes drawn into a layer (§ Rendering system) |
| Platform adapters | `services/Compositor.qml` with `capabilities` and `level` (`utils/Platform.js`) |
| System services | `services/`, kept running by `services/Supervisor.qml` (§ Diagnostics and supervision) |
| Logs and diagnostics | `utils/Log.js` (the one logger), `utils/Diagnostics.js` (the report), IPC `diagnostics` |

## Boundaries

`interfaces.md` is the contract between layers. `tools/check-rules.py` holds it mechanically (`[layers]`):

- Import direction per layer (`LAYER_IMPORTS`): services import no state, components, modules, windows or keybinds; components import no state, services, modules, windows or keybinds; state imports no components, modules, windows or keybinds; config imports nothing from `qs`; keybinds import no components, modules or windows. Relative `import "../x"` counts the same.
- Services declare no visual type (`Item`, `Rectangle`, `Text`, `Shape`, windows, ...) and import no UI module (`QtQuick.Shapes`, `Controls`, `Layouts`, `Effects`, `Quickshell.Widgets`).
- Components read only component-level `Appearance` and `Motion` groups (`COMPONENT_TOKENS`). A component sized or timed by a feature takes `required property var look` and/or `pace` from the module: `ColorWheel` (settings), `EdgePull` (taskbar sizes, `Motion.reveal`).

## Transition lifecycle

`components/Lifecycle.qml` runs one surface's phases: `idle → preparing → entering → active → exiting → idle`, with `recovering` for a reopen during the leave. The moves are a pure table in `utils/Phases.js` (`next(phase, event, canRecover)`); an event a phase does not accept changes nothing, so rapid or out-of-order input can never reach an invalid phase.

- The host sends `show` and `hide` (from `isShown`) and its animations send `prepared`, `entered`, `recovered` and `exited` from a final `ScriptAction`, so an animation that was stopped never reports.
- `show` during `exiting` is an interruption (`interrupted`): it goes to `recovering` when the host can rewind (`canRecover`), else back to `preparing`.
- `moving(from, to, event)` fires before the phase changes (the host captures its leave form there, while it still reads the old phase); `moved` fires after it (the host starts animations there).
- **Recovery**: a watchdog (`Motion.lifecycle.stuck`, longer than any real phase) runs only while a phase is moving. If it fires it logs `vados: lifecycle: <name> stuck in <phase>, settling` and sends `settle`: entering phases land on `active`, `exiting` on `idle`, and the host snaps its values to that end. No surface can stay orphaned half-open.
- Hosts: `Burst` (dashboard, search, settings; recovers by rewinding). Their `isActive`, `isLeaving` and `phase` read the lifecycle.
- **Every leave lands exactly once.** The hosts emit `landed()` through `land()` (guarded by `hasLanded`, reset when a leave starts), from the leave's `ScriptAction` or, when the watchdog settles a leave to `idle`, from `settle`. A settled leave still hands the taskbar back.
- **Leave geometry follows the screen.** At the leave start the host keeps its form with the frame it was drawn in (`heldForm`, `heldFrame`; Burst: seed point and form size). `leaveFrom` is `Geometry.refit(heldForm, heldFrame, frame)`, so a screen resized or a panel moved mid-leave reshapes the leaving body instead of drawing it in the old screen's coordinates. The enter already binds to the live geometry.
- **Overlays sees the phases.** Each overlay module exposes its `phase`; `OverlayWindow` reports it to `Overlays.reportPhase(key, screen, phase)` (§ Overlay engine).

## Compositor boundary

`Compositor` picks a backend once:

1. **hyprland**, when `HYPRLAND_INSTANCE_SIGNATURE` is set. It runs `hyprctl -j monitors` and `activewindow`, 60 ms after relevant socket2 events and every 2 s.
2. Otherwise it starts `driftwm msg --json subscribe`. The first `State` line selects **driftwm**. Each line is a full snapshot (camera, zoom, windows, outputs, fullscreen, pinned). Once driftwm is selected, a `Supervisor` restarts the stream with backoff whenever it exits (§ Diagnostics and supervision).
3. **generic**, when the stream exits before any `State` line (`hasNoCanvas`; the supervisor goes inactive and never retries). It reads `ToplevelManager.activeToplevel` and counts as covered only when fullscreen or maximized.

It publishes:

- `activeWindow`, screen-local and Y-down
- `focusedScreen`
- the raw `canvasState`
- `viewports()`
- the `canvasChanged` signal

Writes go out through `send([...])` / `action("spec")` as detached `driftwm msg` calls, only while `capabilities.windowControl` holds; elsewhere they go nowhere.

**Capabilities** (`utils/Platform.js`, the contract): features ask `Compositor.capabilities` and never which compositor runs. Each backend row answers every key, and claims only what the code implements:

- `activeWindow`, `fullscreenDetection`, `layerShell`: every backend (generic knows the active window only while it is fullscreen or maximized).
- `windowGeometry`, `focusTracking`: driftwm and Hyprland. Without them the taskbar hides only for covering windows and `focusedScreen` stays on the first screen.
- `windowControl`, `freeCanvas`, `windowMinimize`, `windowSnap`: driftwm (IPC by window id; minimize is `Confinement`'s parking, snap is its resize and move, both in Desktop mode).
- `workspaceManagement`: no backend yet (Hyprland workspace events only trigger a refresh).

`Compositor.level` is `core` (generic), `extended` (Hyprland: geometry, no window control) or `native` (driftwm: free canvas and control, so Desktop mode). `Confinement.canConfine` is `freeCanvas && windowControl`, `canMinimize` and `canSnap` add `windowMinimize` and `windowSnap` to Desktop mode, and `maximize()` and `fullscreen()` ask `windowControl`. The README "Compositor support" table is the user-facing copy; `tools/check-rules.py` fails when it and `Platform.js` disagree. Capability tests: `tst_platform`.

## Taskbar hiding

`TaskbarWindow.isCovered = Occupancy.isCovered(screen)`, and `Taskbar.isRevealed = !isCovered || isSummoned`. Dwelling on or pulling the 3 px edge strip summons the bar (`EdgePull` ability: dwell and pull drive the bead, `summoned()` calls `Taskbar.summon`).

## Taskbar side

`Config.data.taskbar.side` anchors `TaskbarWindow` to the left or right edge. The `Taskbar` module is always laid out for the left edge. On the right, `isMirrored` flips the whole module with an `Upright` scale of -1 around its centre, and every readable leaf flips back with its own `Upright`: task icons, idle glyphs, idle expansions, the clock, the title tip text and the carried icon. Pointer coordinates and `mapToItem` go through the transform, so carry and neck logic is unchanged.

**Compact idle column**: every idle circle's pointer area is a `FoldDrag` (`modules/taskbar/FoldDrag.qml`), a `Gesture` that calls `Taskbar.foldIdles(isFolding)` once a press travels `Motion.fold.threshold` up or down, and swallows the click that follows. Down folds, up unfolds. `foldIdles` closes any open idle and emits `compactRequested`; `TaskbarWindow` writes `taskbar.compact` to `shell.json` and feeds it back as `Taskbar.isCompact`. While compact, only idles with `isKeptCompact` (audio, power) stay `isPresent`; the others close their slot (`room`) and pop out, and `FoldDot` (a small liquid bead with three specks, top of the column) pops in. A click on it, or a drag up on it or any idle, unfolds. The compact column is the seed of the activity bar (`roadmap.md`). The input mask lives in the window (`inputZone`, placed from `Taskbar.inputWidth`), not in the transformed module. `Occupancy` checks the edge the taskbar is on.

## Activity pill

Data: `Activities` (service) publishes what is running: `liveKeys` and `order` over `keys` (`call`, `media`), the MPRIS track and controls, the Discord call from PipeWire stream nodes. State: `ActivityState` (`state/`) holds `mode` (`hidden` → `idle` → `active` → `expanded`), the screen it is expanded on and the lead. `CTRL + LEFT / RIGHT` (`GlobalShortcut` `activityPrevious` / `activityNext`, IPC `activity`) call `ActivityState.step` on the focused screen, clamped at both ends. It goes active by itself when the first activity starts and idle when the last stops; a forced state stays until then. `TaskbarWindow` maps `ActivityState.modeOn(screen)` (expanded only on its own screen, active elsewhere) and `leadKey` into `Taskbar.activityMode` / `activityLead`, and `activityModeRequested` / `activityLeadRequested` back. The taskbar asks to fold an expanded pill back to active when it hides, is eaten or goes away.

`ActivityPill` sits at `Taskbar.activityCenter`: the screen's vertical middle, kept below the task pills and above the idle column. Its body is one `LiquidShape` in the taskbar liquid (plus `EdgeFuse` for the fused style), sized by the `Reshape` ability from the state: bead (`activity.bead`), capsule (`activity.width × length`), or the lead's expanded size. Up to the capsule width the body is centred on the taskbar spine; wider, its left side stays at the capsule's left and it grows towards the screen, so it spreads out of the taskbar. `expansion` (0 to 1, overshooting) is its width progress; each expanded view hangs its own liquid off it, which gives each activity its own shape: `ActivityMedia` a disc head concentric with the root cap (`media.head`), `ActivityCall` two drops sliding out of the bottom past `Motion.activity.dropStart`. Running activities other than the lead hang under the active capsule as satellite droplets, each popping in on its own spot (a `Mutate` each, staggered outwards by `Motion.activity.stagger`) once the capsule has arrived. The active face (`ActivityGlance`) is one `Turn` per icon, the glyph first and the indicator a stagger later, so the icons never scale into one point together.

Order of a change: `Mutate` pops the pill in and out (hidden); faces leave at once over `faceLeave`; `Reshape` grows at once (OutBack, lead axis first, the other `lag` behind) or shrinks after `shrinkDelay` (OutCubic, faster); faces enter on `Reshape.isArrived` (`arriveShare` of the move), expanded content staggered by `Motion.activity.stagger`, text through `TypedText`. Clicks: idle → active → expanded, expanded → active; the wheel rotates the lead. Mirroring: the expanded view keeps the mirrored layout (head at the edge); readable blocks (details, art, ring, glyphs) counter-flip with `Upright`. The pill body counts as a taskbar part for overlays (`liquidParts`), and its `reachRight` widens the input zone.

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
| `LabelReveal` | enter, leave (`isShown`) | the V/AS bar sweep: an accent bar grows across `sweepWidth`, the content opens under it, the bar retracts off the far edge; the leave is a cut (clip closes). Plays `<label> enter` / `<label> leave` |
| `Outline` | enter, leave (`isShown`) | a border tracing itself from the top-left corner along both sides to meet at the bottom-right (`Geometry.halfOutline`, `cutAlong`); the leave is its own faster fade. Plays `<label> enter` / `<label> leave` |
| `Press` | click (`isPressed`), hover or selection (`isRaised`) | `Press { target: item; isPressed: area.pressed }`, animates the target's `scale` |
| `Reshape` | size change (`targetWidth`, `targetHeight`) | the activity pill body: grow with overshoot, own faster shrink, `isArrived` cue for the faces |
| `Mutate` | enter, leave (`isShown`) | pill pop, spread and inner reveal cue (`isInnerShown`), `departed()`; task pills spread, idle circles only pop (`hasSpread: false`); the taskbar enter is their staggered `Mutate`s. Task icons enter from the centre outwards: `isInnerShown` fires halfway through the spread, the centre icon turns in then, and each ring further out is deferred (`TaskItem.openingDelay`) so the outermost starts once the spread is full (`Mutate.spreadAfterInner`, at least `Motion.pill.elementStagger` per ring); icons added to an open pill enter at once. With `isArriving` (the taskbar taking over from a released burst) `Mutate` shows at full size at once (`arrive()`) |
| `EdgePull` | hover dwell, drag pull | the hidden taskbar's edge strip and bead; `summoned()` |
| `Rising` | idle (`isRunning`) | bubbles off an open body |
| `Gather` | absorb (`merge`) | taskbar silhouettes pulled into one point |
| `Burst` | enter, leave (`isShown`) | the dashboard and search body born from the taskbar parts at the taskbar column, its root side a `Lobe` into the screen edge, bouncing out into its form; publishes `visitor` while leaving; cues `isOpened`, `isActive`, `form`, `landed()` |

Abilities without visuals are `QtObject`s (`Press`, `Mutate`, `Reshape`), so attaching one never takes a slot in a `Row` or `Column`. A `Behavior` easing a property towards a state value (overlay dim, idle stretch, hover swell, taskbar inset and fuse) counts as an ability. Not yet an ability: the taskbar carry (drag) choreography in `Taskbar.qml`, whose droplet is `Carried`; right click has no animation.

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
| `pill` | `Mutate` pop of task pills (60 ms) | `Easing.OutBack` |
| `circle` | `Mutate` pop of idle circles and the fold dot (220 ms) | `Easing.OutBack` |
| `follow`, `dock` | `Carried` droplet following the finger, docking into its slot | `Motion.springs` |
| `droplet` | `Carried` stretch | `Motion.springs.wobble` |
| `neck` | taskbar carry neck merge and separation | `carry.joinShare`, `snapShare`, `joinKick`, `snapKick` |

Closed-form rises and rings run on an ability's own clock (a linear phase in seconds), so they stay abilities; `pull` runs in a `FrameAnimation`. Leaves are not springs: they keep their own faster easing (`Mutate` InBack), as the animation rules require. A new liquid surface (alerts, clipboard, lock) picks a character or adds one; it never writes `Math.exp` itself.

## Rendering system

Rendering is separate from state and transitions: a host says only whether a surface is shown (`isShown`, its opacity); the rendering components decide which passes run. Two components own every effect, layer and mask in the shell (`tools/check-rules.py`, rule `rendering`); modules and other components compose them.

| Component | Owns | Passes (full) | Passes (lite) | Runs while |
|---|---|---|---|---|
| `LiquidLayer` | the goo: blur + threshold of its `shapes` | shapes texture, blur (`MultiEffect`, `blurMax` = `Rendering.blur(melt)`), blurred texture, rim, fill and core threshold passes, a flattening layer when `fillAlpha < 1` (always: `panelAlpha` 0.94); rim and fill colour textures | shapes texture, fill texture and the core threshold pass only | `isShown && opacity > 0` (`isRendering`); off is `visible: false`, textures not `live`, blur and threshold layers disabled; the colour surfaces are `ShaderEffectSource` textures, never `layer.enabled` (see `quirks.md`) |
| `Masked` | an alpha mask: content cut by the shape in `mask` | mask layer, content layer, one mask pass | same (a mask is layout, not decoration) | it is visible and its opacity > 0 |

Cost: every pass covers the component's whole area and re-renders in any frame where something inside it moves; static frames reuse the textures. A full liquid is about six full-area passes (blur is several downsampled levels), lite two.

| Instance | Area | Shown (`isShown`) |
|---|---|---|
| Taskbar `liquid` | taskbar window | `true`; stops at opacity 0 (bare style, taskbar away) |
| Taskbar `tipLiquid` | taskbar window | bare style while the title tip is up (before 2026-11-07 it ran empty, always) |
| Extension | taskbar window | while the extension is grown; stacks over the taskbar liquid then |
| Search, Dashboard | full screen | `burst.isActive` (enter to landed) |
| Settings | full screen | `launch.isActive`, opacity `launch.material` (0 in the bare style) |
| Search favourites (`Masked`) | full screen | while the search window is present; re-renders every frame of the burst (the wall moves) |
| Best match avatar (`Masked`) | avatar | while the profile picture is loaded and the avatar is shown |

Cheap and kept in modules: `clip` (a scissor rectangle; search body, list and rows, the name pill, dashboard panels, idle pills, the title tip, the network page), plain `Rectangle` dim, and `Shape`s (`CurveRenderer`; paths re-processed on the render thread when their points change). Blur behind overlays is the compositor's (layer rules).

**Quality** (`rendering.quality`, `config/Rendering.qml`): `Rendering.isLite` and `Rendering.blur(radius)`, the one precedence function for blur, like `Motion.pace` for durations. Under lite the liquid keeps its shapes and threshold, so bodies, necks (`LiquidBridge`) and lobes keep their outlines; it loses the rim line and the soft fusion of bodies that only touch through the blur.

| | full | lite |
|---|---|---|
| motion normal | everything | no blur; motion as usual (bubbles still rise, cheap without blur) |
| reduced motion | blur; transitions instant, no bubbles, splashes or crests | the cheapest: instant and no blur |

Precedence: shown (`isShown`, opacity) gates every pass; quality decides which passes; motion only decides timing. Quality never changes durations and reduced motion never changes passes.

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
- `phases` (screen → overlay → lifecycle phase, idle ones dropped), `phaseOf(key, screen)`, `isSettled(screen)` (every surface on it is `active` or gone). When a surface reports `idle`, `Overlays` calls `returnTaskbar` for its screen: the taskbar comes back once nothing is on the screen, even if a `landed()` was lost.
- `keepScreens(names)` (from `shell.qml` on `Quickshell.screens` changes) closes overlays on screens that went away and drops their away flag, parts, gear origin, leaving balls and phases, so an unplugged monitor leaves no exclusive keyboard or gathered taskbar behind.

`windows/OverlayWindow.qml` is the window side: a full-screen `PanelWindow` on the overlay layer, namespace `vados-<key>`, keyboard from `ownsKeyboard`, with `isOpen`, `parts`, `requestClose()`, `land()` and `placeVisitor()` for its module. `SearchWindow`, `SettingsWindow` and `DashboardWindow` are an `OverlayWindow` plus their module. A new overlay is a `kinds` entry and an `OverlayWindow`.

## Gesture engine

`components/Gesture.qml` is a `MouseArea` ability for every drag: `threshold` (default `Motion.gesture.slop`), axes, `dragButtons`; it tracks `travelX/Y` from `pressPoint` and a smoothed velocity (`Motion.gesture.velocityBlend`). Signals: `moved` every move, `crossed` once when the travel passes the threshold, `thrown(travel, velocity)` on release after a drag, `tapped(mouse)` on a release without a drag, `ended` always. Built on it: `FoldDrag` (fold on crossing), `EdgePull` (pull length on `moved`, summon on `crossed`), the task carry in `Taskbar` (`crossed` picks up, `moved` carries, `thrown` lands, `tapped` activates or closes). Named `Gesture` because `Drag` is QtQuick's attached type and wins inside `qs.components` (`quirks.md`).

## Attention engine

`state/Attention.qml` decides whether a notification may interrupt (`rules/interaction.md`). It listens to `Notifications.received`; `mayPeek` lets critical through always, holds low always, and holds normal ones under do-not-disturb (`attention.doNotDisturb`) or while the active window is fullscreen. Admitted notifications gather for `Motion.attention.batch` and then become one `peek` `{ notifications, isUrgent, screen }` on the focused screen, which expires after the longest own timeout (`expireTimeout`, seconds) or `Motion.attention.peek`; urgent peeks stay until dismissed, and a peek drops notifications as they are dismissed. The alert band will draw `peek`; held notifications are still counted by `Activity`.

## Configuration

`shell.json` (`~/.config/vados/shell.json`) is read and written only by `config/Config.qml`, whose `JsonAdapter` exposes it as `Config.data`. What a valid file is lives in one pure table, `utils/Schema.js`: each key (`group.name`) with its `type` (`boolean`, `string`, `colour`, `names`), its `fallback` and, for enumerations, its `choices`; plus `version` (1) and `migrations` (step `n` turns version `n` into `n + 1`).

Load: `FileView.loaded` → next tick `Config.repairLoaded()` → `JSON.parse(file.text())` → `Schema.repair(raw)` = `migrate` (version 0 when missing, a broken version reads as 0, a newer one is read but never written) then `validate` (defaults first; each known key with a valid value is kept; a wrong type or a value outside its choices falls back with a problem; unknown groups and keys are reported and dropped). `Config` assigns the clean values that differ, logs each problem once (`console.warn("vados: config: …")`, with the file's path), and calls `writeAdapter()` only when `shouldWrite` (a migration or a repair). The written file validates clean, so the reload it triggers writes nothing. A file that is not JSON is logged and left alone; the settings stay as they were.

Setters: each `set…` calls `accept(key, value)`, which asks `Schema.findProblem`; an invalid value is refused, logged, and the current value kept. `check-rules.py` holds the schema, the adapter (same keys and defaults) and the README Settings rows in step, and fails a setter that assigns a key it did not `accept`.

The preview and the tests use the `Config` mock in `tools/preview/play.py`; `Schema.js` itself is tested pure in `tst_schema`.

## Persistence

`services/StateFile.qml` is a reusable `Scope` for runtime state: `name` → `~/.cache/vados/<name>.json` as `{ version, data }`, `values` (defaults merged with the file), `update(next)` (debounced `Motion.store.write`), `flush()` (also on destruction), `isLoaded`. A file without `version` is read as plain data; a file that does not parse is copied to `.corrupt`, another version to `.version<N>`, and the defaults are used. Users: `Apps` (launch history, still `apps.json`), `Confinement` (`desktop.json`: parked windows).

`Confinement` waits for `isReady` (state loaded and a driftwm canvas seen) before `recover()`: saved parked windows that still exist are adopted in Desktop mode (so `enter()` never parks them a second time at their parking spot), or put back in Canvas mode; windows that no longer exist are dropped. Every park and restore is saved.

## Diagnostics and supervision

Rules in `rules/reliability.md`.

**Logging.** `utils/Log.js` is the one logger (a `.pragma library`, so one instance per engine and one ring for the whole shell). `Log.info` / `warn` / `error(subsystem, message)` print `vados: <subsystem>: <message>` through `console.*` (which Quickshell sends to its output and the journal). A message already printed within `Log.repeatWindow` (5 min) is not printed again: its entry counts `repeats` and keeps the `last` time, and the first print after the window adds `(repeated N more times)`. The last `Log.capacity` (100) entries stay in memory (`recent()`); the repeat memory is pruned past the same bound. Subsystems in use: `lifecycle` (stuck phases), `config` (schema problems), `weather`, and each supervisor's name.

**Supervision.** `services/Supervisor.qml` is a reusable non-visual type (like `StateFile`), placed beside the work it keeps alive:

- `process`: a `Process` it owns. It sets `running` itself (the host declares no `running:`), starts it while `isActive`, stops it and cancels a pending restart when `isActive` goes false. A stop it asked for is never a failure, even when the process exits only after the surface was shown again (`isStopping`; it then starts at once).
- When the process stops while active, one zero-length timer later (so the `exited` code is in whichever order Quickshell emits `exited` and `runningChanged`) it is a failure: `exited with code N`, or `failed to start` without an exit.
- `fail(reason)`: `failures` (in a row) goes up, the delay is `Backoff.delayOf(failures, Motion.supervision)` (`base` 1 s doubling by `factor` up to `cap` 60 s), it logs `<reason>, restarting in N s` and holds (`isHolding`, status `waiting`). When the hold ends it restarts the process (`restarts` goes up) and emits `restarted()`.
- `succeed()`: after `Motion.supervision.healthy` (30 s) of running, or when the host reports success, `failures` resets and a recovery is logged (`recovered after N failures`).
- Without a `process` it supervises any retried work: the host calls `fail` and `succeed` and redoes the work on `restarted()` (`Weather`'s fetches).
- `status`: `stopped` (inactive), `waiting`, `failing` (restarted, not yet healthy), `healthy`. Every supervisor enrolls in `services/Supervision.qml` on creation and leaves on destruction.

| Service | Supervised | `isActive` |
|---|---|---|
| `Compositor` | `driftwm msg --json subscribe` | not Hyprland and the probe found a canvas (`!hasNoCanvas`) |
| `Network` | `nmcli monitor` | always (the taskbar shows the network) |
| `Removable` | `udevadm monitor` | always (the taskbar shows removable drives) |
| `Traffic` | `ping` | `Traffic.isActive` (dashboard open) |
| `Weather` | the geocoding, IP and forecast requests (no process) | `Weather.isActive` (dashboard open) |

Not supervised: one-shot queries that a poll already repeats (`Hardware` probe, `Network` and `Removable` queries, Hyprland `hyprctl`); a failed run is simply retried by the next poll.

**Diagnostics.** IPC `diagnostics report` (`keybinds/Shortcuts.qml`) returns `Diagnostics.report(Compositor, Overlays, Supervision.supervisors, Log.recent())`, built by the pure `utils/Diagnostics.js`: compositor backend and level, present and missing capabilities, the overlay stack (`key on screen`, bottom first) and each screen's surface phases, every supervisor with status, restarts, failures in a row and the last failure, and the recent log with clock times and repeat counts. The backend name appears there for people only; no feature branches on it.

## Frame debugger

`KP_0` (global shortcut `vados:frames`, IPC `frames toggle`) freezes the shell so one frame of one animation can be pointed at. `state/FrameDebug.qml`:

- **Hold.** `Motion.isHeld` is the one pause flag. Every top-level animation in `components/` and `modules/` declares `paused: Motion.isHeld && running` (`tools/check-rules.py` fails otherwise; `tools/animations.py` finds them). The `running` term matters twice: Qt warns when an idle animation is paused, and an animation that starts while held re-evaluates the binding and pauses at once. Qt clears `paused` when a running animation is restarted, so while held the `heartbeat` (a `FrameAnimation`, which also keeps the animation clock ticking) calls `Motion.holdAgain()` every frame, and `Lifecycle.send` calls it once more through `Qt.callLater`: an animation triggered during the hold starts frozen at frame 0.
- **Step.** `step()` clears the flag; heartbeats are ignored until `arm()` has run (a queued call, so Qt has registered the resumed animations), then their times are added up. The heartbeat sits earlier in the Qt animation list than the resumed animations, so the beat that sees at least `Motion.frames.stepMinimum` (12 ms) advanced pauses them again before they update in that tick: exactly the ticks counted have run (one 60 Hz frame; two on a faster display). `Motion.frames.stepTimeout` resumes by time if the clock stops (logged).
- **Back.** Animations cannot run backwards, so each frame reached (frame 0 of a new animation and every step) is also grabbed as a picture: `captureRequested(token, scale)` makes every `FrameTap` (one per window: the taskbar and each `OverlayWindow`) `grabToImage` its content at `Motion.frames.scale` (1, full resolution) times the screen's `devicePixelRatio`, so a replayed frame is drawn pixel for pixel, into the `history` entry (`counter`, `label`, `shots`, each shot with its `bytes`). `trim()` keeps at most `Motion.frames.history` entries and at most `FrameDebug.memory` bytes of pictures (`Motion.frames.memory`, 1 GiB), dropping the oldest first and never the newest. A grab result and its `itemgrabber:` url die soon after the callback (older ones then fail with `Protocol itemgrabber is unknown`), so each tap also loads the url into a hidden `Image` (the shot `keeper`, `cache: true`) inside the callback: the pixmap cache then serves the url to `FrameStage` later; `FrameDebug.release` destroys the keepers of dropped entries. `back()` moves `cursor`; while it is before the newest entry the HUD (`FrameStage`) shows that entry pictures on a dark ground over the frozen shell and `counter` reads `FRAME n REPLAY`; `step()` then only moves `cursor` forward and runs nothing, so the animation stays at its newest frame.
- **Screenshot.** `snap()` (works held or not) asks the taps for a full-resolution grab (`captureRequested(token, 1)`) and, once every grab answered (`pending`), emits `snapshotReady(shots)`; or reuses the entry being replayed. `FrameWindow` lays the pictures out in the hidden `FrameStage` of its HUD, grabs that, saves it with `Quickshell.cachePath` and pipes it to `wl-copy --type image/png`; `finishSnap()` ends it. Only the shell windows are in it.
- **Names.** `utils/Playing.js` is a `.pragma library` registry: a `Lifecycle` plays `<name> <phase>` while moving, `Mutate` plays `<label> enter` or `<label> leave`. Hosts set `label` on `Burst` and `Mutate`; the HUD lists the names (`x3` for duplicates). `frame` counts steps since the current set of animations started and is 0 when it begins.
- **Playground.** `play.qml` grabs its `scene` item, not the window, so the HUD is not baked into the pictures. Its HUD takes the keyboard while held (`holdKeyboard()`, again whenever something else takes it, such as search opening) and hands it back when released (`returnKeyboard()`). `play.py` runs the window in-process: an event filter turns `Num 0` and `Num +` into `pressShortcut("frames" | "frameShot")` before any item sees them, as the compositor's global shortcuts do in the shell, and `shotSaved(path)` puts the screenshot on the Windows clipboard.
- **Not held:** `Timer`s (the taskbar stagger timers), `Behavior` animations (Qt refuses to pause them: `setPaused() cannot be used on non-root animation nodes`) and anything that reads the wall clock keep running. `Lifecycle.watchdog` waits while held.
- **HUD.** `FrameWindow` is a transparent click-through window on the Overlay layer on the screen that pressed the key, visible while held or snapping, with the keyboard while held; every `OverlayWindow` drops its exclusive keyboard while `FrameDebug.isActive`, so stepping works over search (whose field would otherwise take the arrows), settings and the dashboard alike; `modules/framedebug/FrameHud.qml` maps Up and Right to `step()`, Down and Left to `back()`, Plus to `snap()`, Escape to `close()`.

## Reduced motion

`Motion.isReduced` (`motion.reduced`, settings Settings tab) and `Motion.pace(duration)`, the single precedence function: every duration in components and modules goes through it and is 0 under reduced motion. `Rising` stops emitting (`isEmitting`) and `Burst` has no splashes or crests. `TypedText` and finger-driven motion are content and keep their timing; `Motion.reveal.dwell` is an interaction timer, not motion.

## Interruptions

Surfaces go through their `Lifecycle` (§ Transition lifecycle). `Mutate` re-enters from its current pop (`holdPop`). `Burst` reopened during its leave, before the hand-off (`canRewind`), rewinds the leave (`rewinding`, exit back to 0 over the time already spent) and resumes the enter from the spread and impact it had reached (`resuming`), instead of converging from an empty ball again.

## Settings

`SettingsWindow` is a full-screen overlay layer per screen (namespace `vados-settings`, exclusive keyboard while open), like search. It bridges `Config` into `modules/settings/Settings.qml` and its signals back to `Config.setAccent`, `setTaskbarSide`, `setTaskbarStyle` and `setWindowMode`.

Opening: the gear (`SettingsIdle` → `settingsRequested` → `TaskbarWindow`) or `CTRL + P` (`GlobalShortcut` / IPC `settings toggle`, focused screen) calls `Overlays.toggle("settings", screen)`, which also closes search and the dashboard.

Settings opens with the dashboard and search `Burst`: the taskbar parts stream into a circle at the taskbar column, which explodes along the whole screen (100% of its height, `Appearance.settings.bodyShare` less `rightSpace`, plus `endPadding`, of its width), bounces past the far wall and settles with waves crashing on the walls. Then the taskbar's role changes: a tall accent-coloured pop bar (`TabBar`) pops in inside the body as the main navigation (User, Settings, Customization, Advanced), and a white second pop bar pops in to its right for tabs with deeper levels (Customization: Backgrounds, Pills, Taskbar, Lock Screen; Advanced: Link to VAD/OS, Services). The page content slides right when the second bar appears.

1. **Merge**: every taskbar part is drawn into the gear pill, near ends first (`mergeLag`), while the gear swells into one ball (`Appearance.settings.ball`).
2. **Shoot**: from the gear, the ball crouches away from the panel (squash), then fires straight to the panel centre, stretched by speed with three trailing droplets that catch up.
3. **Pop**: impact squash and inflate along the flight line, then the bubble bursts open into the panel. Width and height wobble in antiphase (the `launch` character, `Liquid.ring`), and splash droplets ride just ahead of the wave front and settle back into the edge. Content `Turn`s in at `contentShare`, and `Rising` bubbles start leaving the top and bottom edges for the screen edges.
4. **Tab bar**: a circle buds out of the container's left edge (OutBack), then extends into the `TabBar` pill, and its items enter.

Tab switch: the highlight slides, the old page leaves (`Motion.settings.pageSwap`) before the new one enters. Left/Right step the second bar, Up/Down/Tab the main one. Close is the burst's own leave: content out, the body collapses into the circle at the taskbar column, and the taskbar comes back out of it like after the dashboard.

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

1. **Converge** (`converge`, linear: the nearest part moves on frame 1): every taskbar part flies to the seed point (the taskbar column, `seedX`, at the overlay's height), nearest first (`convergeLag` delays the farthest). A long part first retracts into a circle of its own width (`shrinkShare` of its progress, scaled by how much longer than wide it is, so the task pill needs the most and a circle none), then flies in (`travelStart`), and is swallowed by the ball as a circle shrinking to nothing (`absorbShare`). There is no ball before: the ball is only the mass that has arrived (`ball · √arrived`), so it is born from the parts.
2. **Charge**: the ball inflates and squashes (`impactShare`, `inflate`, `squash`).
3. **Bounce out** (`spread`): width and height follow the `burst` character (`Liquid.rise`, launched at `expansion` so it is `1 − e^(−σt)·cos(ωt)`), over the spread's seconds. The height leads (`heightLead`), so the body first stands up between the top and bottom walls, then shoots out along the dashboard, overshoots the far wall by about 15 % and snaps back, stretched thinner while overshooting (`drag`). The root side settles onto the root wall early (`rootShare`).
4. **Waves crash**: when the height first reaches its walls one wave per side (a single `Shape` bump, `crestLength` long, drawn along the wall path by `wallPoint`) starts at the root on the top and bottom walls, runs along it, wraps round the far corner curve and meets the other on the far wall at 50% height (`crestRun`). The meeting starts `impact` (its own timeline, paused until `meetShare` of the spread): the two halves fuse into one mound that swells and sinks into the body, a jet droplet leaps off the far wall and falls back, and the body bounces like a puddle hit by a drop (far wall dents in then out, height the other way, damped: `impactPush`, `impactCycles`, `impactDamping`). A droplet also splashes off each far corner (`splashSpan`).
5. **Steps**: two rectangles in the liquid give the body a step: the top from the root to `stepTopShare` of the width rises `stepTop` above it, the bottom from the root to `stepBottomShare` drops a bigger `stepBottom` below it. Both scale with the body height, so they grow in and shrink away with it. While they show (`isStepped`), the root `Lobe` grows by their rises (`aboveRise`, `belowRise`) and shifts its centre, so the edge curve covers the steps too. With `hasSideStep` (the host sets it when `Battery.isPresent`), a third step (`stepForm("side")`) grows out of the far wall, `stepSide` deep and `stepSideHeight` tall, centred `stepSideOffset` below the middle, from the moment the waves meet until the overshoot ends (`spread` from `meetShare` to 1), so it lands with the body's bounce. It rides the impact wobble with the wall.
5. Content `Turn`s in by distance from the root (`Motion.dashboard.reveal` ms per px) once `openShare` (0.14) of the spread has passed; `Rising` bubbles leave the top and bottom surfaces.

**Rounded corners**: where the flat top or bottom meets the far wall, `Burst.roundedOutline` cuts the corner into an arc (`Geometry.roundCorners`): radius from the front corner (`form.right`) towards `edgeRound` as the wall grows, fading to 0 within `edgeRoundFade` of a screen edge so the corner melts into it; the body's height closes the last `edgeSnap` pixels to the screen edge by itself, so the top and bottom merge with the edge instead of leaving a sliver. Without the rounding the polygon that replaces the rectangle once the wall exists had square corners (a straight edge on the ball, 2026-11-09).

**Root fused to the edge**: the whole root side is a `Lobe` (the search lobe shape) from past the screen edge (`edgePad`) to `rootSpan` inside the body, flaring wider at the edge by `rootSwell` (scaled by `swellShare` while small), so the dashboard curves into the screen edge the way the search band does. It follows the body through enter and leave. The crest track starts at the screen edge and runs over this flare (`Lobe.bendAt`, sampled every `curveStep` pixels) before the top and bottom edges. **The wave skips the screen edges**: every crest and trough offset is scaled by `freeShare(point)`, 0 within `Appearance.burst.edgeHold` of the taskbar edge, the screen top or the screen bottom (`screenHeight`, set by the host), rising to 1 over `edgeFade`. So the dashboard's wave fades in as its root flare leaves the edge, and search's full-height column shows it only on the far wall, never along its top, bottom or root.

Leave (own, faster; user, 2026-11-09: the taskbar comes out of the closing overlay, as it went into it on the enter):

1. **Collapse**: content out, bubbles drain, a short hold (`leaveHold`), then the body scales down to the `leaveBall` circle at the taskbar column with its root side on the screen edge (`exit` to `leaveShrink`, OutCubic collapse).
2. **Release** (`releasing`, `release` 0 → 1 over `Motion.burst.release`, linear): every taskbar part it took (`parts`, the gear included) leaves the ball as a circle of its own width, all at the same frame (no lag), grows to full size within `releaseEmerge` of its travel, flies to its place (`releaseTravel` of the release, an ease-in-out, no bounce, so no part has covered much of its way after one frame) and starts extending `releaseExtendLead` (about two frames) before it gets there, so the stretch to full length is already under way on arrival; it extends to its full length (the task pill stretches from a circle into the pill) over `releaseExtendSpeed` (0.7) of its span ending at its arrival, with `Geometry.rebound` (`releaseRebound`) so it overshoots a little and settles; the entries are not delayed, since arrival stays where it was. The idle pills keep the released circle as their body and show their icons one after another, the first on arrival (`Mutate.hasArrivalPop`, `Motion.reveal.arrivalStagger` per order after the first). A part arrives when its extension is done (`arrivalOf`: `releaseTravel` for a circle, 1 for the longest part), so the circles arrive first, the activity pill next and the task pill last. The ball is only the mass not yet released (`leaveBall · √(1 − releasedArea)`, by travel), so it necks into the parts and drains as they leave.
3. **Hand-over, part by part**: `Overlays.placeVisitor` gives the taskbar back as soon as the release starts (`release > 0`), and `Taskbar.isArriving` is true from then on. Each pill's `Mutate` waits at size 0 (`wait()`) until its own part has arrived (`hasArrived`, from `visitor.arrivals` through `Taskbar.hasArrivedAt`), then jumps to full size (`arrive()`) and its icons, satellites and splits play in at once (task items after a random delay up to `Motion.reveal.arrivalScatter`). At `release` 1 `landed()` ends the overlay.

Without parts (the `bare` style, or another overlay was open first) the old leave runs (`leave`): the body shrinks to the ball while sliding out past the edge (quadratic travel), and the taskbar comes back at the hand-off below.

**Touching the taskbar on leave**: while leaving, `Burst.visitor` (`{ x, y, width, height, isHandedOff, hasReleased }`, left-edge coordinates) goes `Dashboard.visitor` → the window → `Overlays.placeVisitor` → `TaskbarWindow` → `Taskbar.visitor`. `Taskbar.touchOf(centerX, top, bottom, halfWidth)` gives each task pill and idle circle a 0–1 closeness to it (within `Appearance.taskbar.visitReach`), which swells the pill by up to `visitSwell`. In the release leave the taskbar is away until the parts have landed, so nothing is handed off; without parts, once it has become the ball (`exit >= leaveShrink`) it is handed off (`canHandOff`, off for the `bare` style, whose liquid is invisible): `Burst` stops drawing it and the taskbar draws the same ball and edge lobe in its own `LiquidLayer`, so it goos and necks with the pills it passes. The windows are separate layers, so a shape can only fuse with the pills inside the taskbar's own layer.

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

The far wall (from the user's second sketch, 2026-11-06) is part of the `Burst` body: Search passes `wall` (points traced from the drawing, `Appearance.search.wall`, converted to `[x offset from the full far edge, y share]`) and `Burst` draws it in its own liquid. Each point sits at `formRight + offset × wallShare`, `formTop + share × form.height`, so the wall grows, squeezes and bounces with the body every frame. `wallShare` is the body's width progress after the impact (it overshoots with the bounce) and collapses with the leave. `Burst.traceSpline()` turns the points into one Catmull-Rom outline (`wallOutline`, a sample every `Appearance.burst.curveStep` pixels of each span, `curveSlack` covering the bend), so the wall is a single S-wave. Rounded corners on the track (arc segments) are sampled the same way. The crest and trough push each point along its segment's normal; where segments meet at an angle `joinPoints` sweeps the normal round the corner (a round join), and within `seamBlend` of mid-height, where the top and bottom tracks meet, the normal turns level and the offset fades out, so the two halves meet without a notch. The body and crests are filled with `WindingFill` through the `CurveRenderer`, so they are antialiased and small offset loops never cut holes. The wall: in past the favourites, out round the best match, in again near the bottom, flaring at both screen edges. The fill starts `form.right` inside the column edge, so the body's corner never shows a notch.

A walled body is one polygon (`bodyOutline`) traced along the top and bottom tracks (`topTrack`, `bottomTrack`, shared with the crest; all three, and `crests`, are written by `trace()`, queued once per frame with `Qt.callLater`), with the wave's troughs cut into it beside the crest; its wall ends curve inward until `flare` turns them outward into the screen edges after the bounce; Search's mask top and bottom (`maskTop`, `maskBottom`) follow them. With a wall, the burst's crest runs along `wallOutline` instead of the plain far side, the jet leaves from the wall at mid-height (`farFront`) and the corner splashes leave from the wall's ends. Search reads `burst.wallOutline` for `wallReach` and the favourites mask; the click bands (`wallBands`, one `MouseArea` each) come from the settled wall (`settledWall`), so the `Repeater` is not rebuilt every frame; `presence` (`bud` × `wallShare`) only drives content (row shortening).

Content, placed with `edgeX` (mirrors to the right edge):

- **Favourites** (`AppTile`): a grid filling row by row, `favoriteColumns` across (more columns once there are more than `favoriteColumns × favoriteRows`) and `favoriteRows` down, at the top from the list's left edge. It sits in a horizontal `Flickable` (scroll or drag); tiles leaving the taskbar side fade over one cell. The strip is masked by `wallMask` (the same wall path from the screen edge, through a `MultiEffect` mask), so tiles are cut by the curved wall, as drawn.
- **List** (`ResultRow`, in `bodyClip`): every result after the best match, from the top to the field, resting `listLead` below the top so it starts under the favourites. Rows scrolled up into the favourites band fade (`fade`), shrink by `rowShrink` and lose their name first, leaving faint icons under the first favourite column. Rows beside the best match get a `room` from `Search.rowRoom(rowTop)` that ends `lobeGap` before its circle, so the name elides at the end; that part has no fade.
- **Best match** (`FoundCard`): a circle (`found`, wash fill, `ringStroke` ring, accent while selected) with the icon (`foundIcon`) inside, at `foundX` from the root and `foundShare` of the height. Its name is in a liquid pill outside the wall (`nameReach` past the wall's widest point), joined to the circle by a `tether` line. The pill is a `LiquidShape` in Search's liquid layer sized from `FoundCard.nameSpan` / `nameThickness`, so it necks with the wall; `FoundCard.bloom` (a `Behavior`, OutBack in over `Motion.search.nameGrow`, InQuad out over `nameShrink`) grows it from a droplet at the wall side to the far side, its height opening from the vertical middle first (`nameHeightLead`), and the name is revealed by the clip.
- **Field**: the wash pill at the bottom of the column, with the result count and the search glyph on its right.

Content `Turn`s in by distance from the root (`Motion.search.ripple` ms per px, plus a row stagger); while typing, new rows use only `settledStagger`.

Keys: arrows move inside a zone. From the best match, toward the taskbar or down goes to the list and up goes to the favourites. From the list, away from the taskbar goes to the best match and up from the first row goes to the favourites. From the favourites' bottom row, down goes to the list. Directions mirror with the side. Tab and Shift+Tab cycle the zones; Enter launches; Escape clears the query, then closes.

**Overlay swap** (2026-11-09). Opening an overlay while another one is showing on the screen is a swap (`Overlays.swaps`, per screen). The first (`isHandingOver`) leaves without giving parts back (`Burst.isSwapped`, latched at the start of its leave): it collapses to a circle of `look.ball` at the taskbar column, hides itself at `leaveShrink` and lands. The next (`isWaiting`) stays hidden until that landing (`settleSwap`), then starts from the circle (`hasCircle`: `merge` is 1, no converge), so the two bodies never overlap and the taskbar stays away. The swap ends when the next one is active or closed.
