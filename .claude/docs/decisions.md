# Decisions

## 2026-11-07 (architecture from direction.md: logging, diagnostics and supervision)

- **The logger is a `.pragma library`, not a singleton.** A JS library is shared by every importer in the engine, needs no mock in the preview, and can be imported by any layer, `config` included (`Config` logs schema problems); a singleton service would be out of reach for `config` and `components`. Its two constants (`repeatWindow` 5 min, `capacity` 100) live in `Log.js` itself: a library cannot read `Motion`, and passing a policy on every log call would clutter each caller. Calls take an optional `now` so tests are deterministic.
- **Repeats are held for 5 minutes**, longer than the backoff cap (60 s), so a service failing at the cap prints once per 5 minutes with a count instead of once a minute, while a different message is never held back.
- **`Supervisor` is a services-level type, not a component.** Services use it, and services may not import components (`LAYER_IMPORTS`). It follows `StateFile`: a reusable non-visual `QtObject` in `services/`, configured by properties. The registry (`Supervision`) is a separate singleton so the report can list every supervisor without each service exposing one.
- **The supervisor owns `running`.** The first design kept the host's `running: isActive` binding and only restarted; a restart has to write `running`, which breaks the binding, so the process would no longer stop when the dashboard closes. The supervisor now starts and stops the process from `isActive` itself.
- **A healthy run is measured by a timer, not computed at the next exit.** Resetting at the next failure would never log the recovery; a 30 s timer per running process (only while active) logs `recovered` when it happens. So `Backoff.js` is only the delay.
- **One supervisor with or without a process.** Weather's fetches are not a process but need the same backoff, logging and listing; `fail` / `succeed` / `restarted()` give that without a second mechanism. Network and Removable monitors are always active because their surface (the taskbar) is always shown; Traffic and Weather follow the dashboard.
- **No give-up.** A missing binary retries every `cap` for as long as its surface is shown; the cost is one spawn a minute and one held log line, and a binary installed later starts working without a shell restart.
- **The compositor probe is not retried.** A stream that exits before any `State` line means "not driftwm" and selects the generic backend for good, as before; retrying would spawn `driftwm msg` every minute on every other compositor.
- **Diagnostics are built by a pure function the IPC handler calls**, not by a state singleton: the inputs are already public (`Compositor`, `Overlays`, `Supervision`, `Log.recent()`), and a pure function is testable without them. It prints the backend name for people; the capability rule (features never branch on the name) still holds.

## 2026-11-07 (architecture from direction.md: boundaries and compositor contract)

- **Import direction is checked per layer, not per file pair.** `LAYER_IMPORTS` lists what each folder may not import (`qs.x` or `"../x"`), so a new file inherits its layer's rule. No exception was needed: no service reads state, no component reads a service, today. `state/` may import services (`Activity` reads `Notifications` and `Tray`, `Attention` reads `Compositor`): state is the sideways channel built from service data.
- **Modules may import `state/`** (none does yet): it is the documented sideways channel, so blocking it would push features back into window glue.
- **"No UI in services" is a list of visual types and UI imports**, not "only `Singleton` roots": services legitimately hold `Process`, `Timer`, `FileView`, `LazyLoader`, `Connections` and the `StateFile` type.
- **Component-level token groups are an allowlist** (`COMPONENT_TOKENS`), so a new feature group is caught without touching the checker; a new shared group is a deliberate edit. Component-level: `Appearance` `unit`, `radius`, `color`, `font`, `liquid`, `rising`, `burst`; `Motion` `isReduced`, `pace`, `stateDuration`, `hoverIn`, `hoverOut`, `press`, `pill` (the mutation character every pill shares), `type`, `gesture`, `lifecycle`, `burst`, `rising`, `liquid`. `Motion.reveal` is the taskbar's edge reveal, so it is a feature group.
- **Feature values reach a component as `required property var look` / `pace`, not as defaults.** A default pointing at `Appearance.settings` is exactly the coupling the rule forbids, and `required` makes a missing value a load error instead of a silent fallback. `Launch` and `ColorWheel` take the settings groups from `Settings`, `EdgePull` takes `Appearance.taskbar` and `Motion.reveal` from `Taskbar`. `EdgePull`'s dwell stays an interaction timer outside `Motion.pace` (`edgePull.pace.dwell` joins `TIMERS_NOT_MOTION`).
- **Capabilities claim only what the code implements.** `workspaces` became `workspaceManagement` and is false on Hyprland too: Hyprland workspace events only trigger a refresh, nothing manages workspaces. `windowMinimize` and `windowSnap` are true only on driftwm because `Confinement` emulates them over `windowControl` IPC (parking, resize and move) in Desktop mode. `focusTracking` is false on generic: `focusedScreen` never leaves the first screen there. `fullscreenDetection` is true everywhere (driftwm snapshot, Hyprland `fullscreen`, foreign-toplevel `fullscreen`).
- **Global shortcuts are not a capability.** `GlobalShortcut` is declared on every backend and simply never fires where the protocol is missing; nothing branches on it. The README notes the key binding per compositor under the table.
- **The README table is checked against `Platform.js`, not generated from it.** The README stays hand-written prose with a "Without it" column, and the checker compares the three backend columns cell by cell (`yes` / `no`).
- **Capability tests moved to `tst_platform.qml`** with the degrade path of Desktop mode (real `Confinement`, mocked `Compositor`), instead of growing `tst_geometry`.

## 2026-11-07 (architecture from direction.md: rendering system)

- **Quality is its own config singleton, `config/Rendering.qml`**, not a group in `Appearance`. It mirrors `Motion.isReduced` and `Motion.pace`: `Rendering.isLite` and `Rendering.blur(radius)` are the one precedence for passes, the way `pace` is for durations. `Appearance` stays a table of tokens, and the rendering workstream owns a file nobody else edits.
- **Lite drops the blur and the two passes that need it, nothing else.** The core threshold pass already draws the body from the unblurred shapes, so lite keeps shapes, threshold, necks and lobes and loses only the rim line and the fusion of bodies that merely touch. A smaller blur radius was the other option; it still pays for the blurred texture and three mask passes, which is most of the cost.
- **Masks stay under lite.** The search favourites mask cuts the tiles at the wall; without it they would draw outside the body, so it is layout, not decoration.
- **Two rendering components, not one per effect.** Every effect in the shell was either the goo (`LiquidLayer`) or an alpha mask (search favourites, the avatar), so `Masked` took over both masks and the checker allows effects only in those two files. `clip` (a scissor) and `Shape` are not effects and stay in modules.
- **Off is invisible, not live and unlayered.** An invisible or transparent subtree is already skipped by the scene graph, but a texture left `live` and a layer left enabled are an easy way to start paying again; binding them to `isRendering` makes it testable (`tst_rendering`) and checkable (no literal `true`).
- **`isShown` is required on `LiquidLayer`.** Qt refuses to create a layer without it, and the checker refuses one that sets `visible` instead. It found the taskbar's tip layer, which ran its blur and three passes empty, over the taskbar's own layer, in every style but bare.

## 2026-11-07 (architecture from direction.md: configuration validation and migration)

- **The schema is a pure table in `utils/Schema.js`, not QML.** It is tested without Quickshell (`tst_schema`) and read by `Config` for both loading and setters, so one table decides what a valid setting is. The adapter keeps its typed literal defaults for readability; `check-rules.py` holds them equal to the schema's fallbacks and keeps the schema, the adapter and the README rows to the same keys.
- **An invalid value falls back to that key's default, not to the last good value.** On load there is no last good value; a setter keeps the current value instead, because there is one. A `search.favorites` list with one wrong entry falls back whole to `[]`, so the rule stays one sentence.
- **Unknown keys are reported and dropped from what the shell reads, and never trigger a write.** Keeping them aside in a second file was rejected: nothing would read it. Writing only for unknown keys would rewrite the file on every load if `JsonAdapter` keeps them.
- **Missing keys are not repairs.** A hand-written file with three keys takes the defaults silently and is not rewritten; only a migration or a replaced value writes the file back, which ends any reload loop because the written file validates clean.
- **Migrations are a list of steps from version `n` to `n + 1`.** Version 1 is the current layout; a file without `version` is version 0 and its step is the identity, so it migrates by validation and gets `version: 1` written. A file from a newer shell is read for the keys this shell knows and never written back on load. A file that is not JSON is never touched.
- **`rendering.quality` (`full`, `lite`) is added for the rendering workstream** with a setter and no reader yet.

## 2026-11-07 (Phase 1 closed: overlays meet lifecycles, live leave geometry, frame budget)

- **`Overlays` keeps phases but does not drive the lifecycles.** The window reports the module's phase; `Overlays` uses it only as a safety net (an idle screen gets its taskbar back) and for queries. Driving the lifecycle from `Overlays` would have moved choreography into state; the modules still decide from `isOpen`.
- **A lost `landed()` is fixed twice, on purpose**: the host lands on `settle`, and `Overlays` returns the taskbar on `idle`. The first keeps the host's own leave side effects (search clears its field), the second covers any future surface that forgets.
- **Refit the kept leave form instead of recapturing it.** Recapturing on every screen change would need the old phase values; scaling the kept form from the frame it was drawn in to the current frame is one pure function, testable in `tst_geometry`.
- **Screens that go away are pruned from `shell.qml`, not inside `Overlays`.** `Overlays` is loaded by the preview, which has no `Quickshell.screens`; `shell.qml` is not previewed and already owns the `Variants` over screens.
- **The frame budget is measured by stepping the real search module**, not by timing live frames. Offscreen frame timing mixes rendering, the test runner and timer jitter; stepping `spread`, `impact` and `exit` and timing the bindings and `trace()` together with a Python `perf_counter` clock measures exactly the script work the rule budgets. Best of three sweeps at the 95th percentile, because this container's timings vary by a factor of two between runs.
- **The first measurement failed** (4.3–5.6 ms): the wall outline was a binding chain over arrays, re-traced on every property write, twice per frame (`spread` and `impact`). It is now traced once per frame in `trace()` (1.9–2.3 ms). The wall and the body outline now update in the same pass, which they did not before.

## 2026-11-07 (direction: engine integrity first)

- **The user's direction document is the product plan** (`direction.md`): one coherent interaction engine built as independently testable subsystems, progress measured by the foundations, Phase 1 (engine integrity) and a complete taskbar-and-search slice before more features. The roadmap is reordered into its phases.
- **The transition state machine is a pure move table plus a small component**, not a state machine per surface. `utils/Phases.js` holds the table, so it can be fuzzed without QML; `Lifecycle.qml` holds the phase, the signals and the watchdog. `Burst` and `Launch` keep their choreography and only report phase ends, so the motion did not change. Qt's `StateMachine` was not used: it lives in a separate module (`QtQml.StateMachine`), its states are objects that are hard to read as data, and it gives no help with the recovery we need.
- **Two signals, `moving` and `moved`.** A host must capture its leave form while it still renders the enter (before the phase reads `exiting`), and must start animations only after the phase changed, because a zero-length animation under reduced motion reports its end at once and would otherwise be ignored by the old phase.
- **`settle` snaps, natural ends do not.** Stopping an animation from its own final `ScriptAction` is unsafe, so the host only stops and snaps on the watchdog's `settle`.
- **Recovery by watchdog, 3 s.** The longest real phase is about 1.3 s (the settings enter). The timer runs only while a phase moves, so idle still costs nothing.
- **Capabilities are a table per backend, not probed.** Each backend's abilities are fixed by how `Compositor` talks to it (only driftwm takes `send`), so a table is exact and testable; probing can replace a row once a backend's features vary by version.
- **`Mutate`, `Turn` and `Press` stay without a lifecycle.** They are small abilities that already re-enter from where they are; the rule covers surfaces with a separate leave animation.

## 2026-11-07 (engines and enforced hard rules)

- **All four engines and the rules at once, enforced by a checker** (user: introduce all of it and enforce these hard rules; a polished desktop like Caelestia, but thought further). Rules that can be checked mechanically are in `tools/check-rules.py` and run as a Stop hook; the rest are marked as review rules in `docs/rules/`. A Stop hook rather than a pre-commit hook, because the user commits from Windows and the hook already runs for every agent turn.
- **Overlay engine replaces `Visibilities`**, not a wrapper around it. The per-overlay functions are gone; overlays are keys in `Overlays.kinds` on layers. It fixed two known issues on the way: switching overlays gathered an empty taskbar (now the first gather's parts are kept), and two leaving overlays overwrote each other's ball (now one entry per overlay). It also fixed one nobody had hit: the taskbar on screen A never came back when an overlay opened on screen B (`awayScreens` instead of one `taskbarAwayScreen`).
- **`OverlayWindow` base instead of a registry of window instances.** Windows stay thin layer-shell hosts per screen, as the architecture rules want; the base carries only what every overlay repeated (anchors, layer, namespace, keyboard, the `Overlays` bridges).
- **Gesture: one ability, release decides.** Built on `MouseArea` so hosts keep `onPressed` for hit tests (the task carry rejects presses off a task). `tapped` replaces `clicked` because `MouseArea.clicked` also fires after a drag; that is why `FoldDrag` needed a `hasFolded` flag before.
- **Attention is policy in `state/`, not in the notification service.** The service owns the D-Bus role; whether to interrupt depends on the compositor (fullscreen), the user's quiet setting and later the lock screen, which a service should not combine.
- **Persistence: `StateFile` as a reusable type, not one store singleton.** Each feature owns its file and its version, so a corrupt clipboard history can never take the launch history with it.
- **Reduced motion is instant, not slower** (V/AS `animation/08-degradation.md`): `Motion.pace` returns 0. A shortened time scale would make idle motion shake. Do-not-disturb and reduced motion got a SYSTEM tab in settings; taking over the notification daemon stays IPC only, because turning it on replaces the user's daemon.
- **Tests run in Qt Quick Test through PySide6**, on the same mock tree as the preview, with fakes for the Quickshell types an engine needs. Writing them found three bugs the preview alone hid: `Drag` colliding with QtQuick's type, `StateFile.data` shadowing `Scope.data`, and `Jolt` missing its config import.

## 2026-11-06 (liquid engine, activity state, notifications)

- **One liquid engine, not physics per feature** (user: one reusable system with configurable parameters, so VAD/OS has one physical identity). The material, shapes and the burst were already shared; the physics were four hand-written oscillators with their own names (`Burst` bounce and impact, `Launch` wave, `Carried` springs). They are now characters in `Motion.liquid` run through `utils/Liquid.js`.
- **Three parameters, not seven.** The user's list (mass, elasticity, damping, expansion force, merge threshold, separation force, settling duration) is redundant for a spring: mass only matters against stiffness, and settling follows from response and damping, so setting all of them independently would contradict itself. A character is `response` (mass and elasticity), `damping` and `expansion` (launch speed), the V/AS parameterisation (`components/29-physics-motion.md`). Merge and separation are the neck's `merge`, `separate` and their kicks; the material's threshold is `Appearance.liquid`.
- **Characters run in seconds, not in shares of a duration.** The old oscillators were written in a share of their animation, so changing a duration also changed the spring. A character's feel now stays put when a choreography duration changes. The converted values reproduce the old curves within 0.01 % (`Burst`, `Launch`) and the integrator exactly (`Carried`).
- **The engine is a JavaScript library, not a singleton.** Pure functions on a character, like `Fuzzy.js`: no QML property overhead in the burst's per-frame trace, and nothing to mock in the preview.
- **`Mutate`'s pop is a spring; its leave keeps InBack.** The pop was `Easing.OutBack`, which a spring from rest cannot match (9 % off). With a launch speed (`expansion` 1) it matches within 1.7 % over the pop (peak 1.093 against 1.10). Idle circles and the fold dot pop over 220 ms, so they get their own time-scaled character (`circle`) instead of a stretched clock. Leaves are not springs (animation rules: a leave is its own faster motion).
- **Not moved onto the engine**: `Press`, `Carried`'s lift and the tab bar bud still use `Easing.OutBack`. They are press and bud feedback, not liquid bodies; they can become characters when they should share the identity.
- **Activity state merges the sources; the bar only reads it** (agreed step 2). `state/Activity.qml` decides what is current, so the taskbar, alerts and any later surface agree on it. It reads services, which is a downward read.
- **The notification server is off by default** (`notifications.enabled`). Owning `org.freedesktop.Notifications` replaces mako, dunst or swaync, and the shell has no surface that shows notifications yet; turning it on now would make notifications disappear. Turn it on once the activity bar shows them.

## 2026-11-06 (wall flares after the bounce)

- **The wall's end flares turn outward only after the bounce** (user: the curves into the screen edges should appear after the bounce, and be inward until they expand outward). `Burst.flare` rises from `Motion.burst.flareStart` of the opening (the height has settled to under 1 % by then) and retracts over `flareRetract` of the leave; at 0 each end point is mirrored inward about its neighbour, so the corners round into the body, and at 1 they reach the drawn flare.
- **The body stays joined to the screen's top and bottom through the bounce** (user: the edges should be connected before the bounce). A tried keep-clear gap that held the body off the edges until the flares was dropped.
- **The wave cuts troughs into the body beside its crest** (user: a wave is low, high, low, so the burst should open two gaps). With the edge pressed against the screen the outward crest is off screen; the troughs (`Appearance.burst.trough`, `troughLength`, scaled with the crest) are what show. A walled body is therefore one polygon (`bodyOutline`) traced along the same top and bottom tracks as the crest, displaced inward by the troughs, instead of the rounded `Rectangle` plus a wall fill: a separate trough shape cannot subtract from the liquid layer. Bursts without a wall (dashboard) keep the `Rectangle` and have no troughs. Search's content mask follows the wall's ends (`maskTop`, `maskBottom`) so tiles stay inside the rounded corners.
- **The tracks, body outline and crests are traced once per frame** (user: search lagged at the end again). As bindings they re-ran on every intermediate change of `form`, `wallOutline` and the root `Lobe`'s derived values, about six times per frame per side (preview: 7–8 ms of script per frame). `trace()` now runs through `Qt.callLater` from `form`, `impact`, `wallOutline` and `hasTracks` changes, so the calls of one frame collapse into one (about 2–2.6 ms per frame). The cost is that these shapes lag the rest by up to one frame; the `Rectangle` stands in while `bodyOutline` is still empty.
- **The burst is slower** (user: too fast for the eye to follow): `spread` 560 → 900 ms, `impact` 640 → 1000 ms. This is shared with the dashboard.

## 2026-11-06 (search lag and liquid name pill)

- **The crest is traced in one forward pass** (user: search laggy at the end of its animation). `crestPath` used to walk the whole wall track from its start for every one of its 74 samples per side; with the traced wall that track has about 110 segments, which cost about 12 ms of script per frame during the impact (preview benchmark: 15 ms per impact step before, 2.4 ms after, together with the next point).
- **The wall's click bands use the settled wall**, not the live one. The live outline changes every frame, so the `Repeater` rebuilt every band each frame; the bands only matter once the body has settled.
- **The best match's name pill is liquid and grows out of the wall** (user: it should expand from left to right around its vertical middle, it appeared whole, and the burst did not show on it). A `LiquidShape` in Search's layer instead of a wash `Rectangle` in a `Turn`, so it necks with the wall; it is not a second `Burst`, since a single pill needs only a width and height growth, not the column's merge, root and crest.

## 2026-11-06 (search wall inside the burst)

- **The far wall is drawn by `Burst`, not by Search on top of it** (user: the right-side layer was not affected by the wave and not connected to the body, frame by frame). A separate shape anchored only to `formRight` with full screen height, scaled by its own `bud` timeline, detached whenever the body was shorter or mid-bounce. Inside `Burst` its points follow `form` (top, height, far edge) and `wallShare` (the body's own width progress), so it bounces, squeezes and leaves with the body, and the crest, jet and corner splashes run along it.
- **The crest starts at the screen edge and runs over the root flare** (user: the burst did not cover the curves at the screen edges, dashboard too). The track is sampled from the `Lobe` curve itself (`bendAt`), so both stay one shape.

## 2026-11-06 (search redrawn: one traced wall)

- **The wall is traced from the user's drawing, not built from shelves and lobes** (user: keep the curves identical to the drawing; the old wall was very off). The points live in `Appearance.search.wall`, with x in best-match radii from its centre and y as a share of the screen height, and are joined by a Catmull-Rom spline in a `PathSvg`. Scaling x by the best match's radius keeps the drawn shape with the content at any screen width; the height share stretches it to the screen. This replaces the shelf, bulge, waist and fillet geometry of the entry below.
- **Favourites are a horizontal strip, not a shelf behind a divider** (drawing: "scroll / draggable" over the favourites, "fading here" on the first column). They fill row by row and scroll sideways. The wall masks them (`MultiEffect`), so the last column is cut by the curve as drawn, rather than clipped by a straight edge.
- **The list scrolls up under the favourites, fading** (drawing: small faded icons under the first favourite column). Its names go before the icons, so faded rows do not write over the favourite labels.
- **The best match is a ringed circle inside the body, its name in a pill outside** (drawing). The arc on its taskbar side is gone; the ring shows selection instead.

## 2026-11-06 (search lobes over the list, superseded by the entry above)

- **The bulge is a true circle with circular fillets** (user: the curve was elliptic). The cubic bulge could not stay round while its necks stretched it vertically. `PathAngleArc` with explicit centres is used instead of `PathArc`, whose large-arc and direction flags kept picking the other circle through the same endpoints (`quirks.md`).
- **The shelf flows straight onto the bulge** (user: the step was too brutal). Dropping back to the column between them left only about 40 px of height for a 250 px step; joining the circle's upper-right side tangentially at `bulgeJoin` makes the step about three times taller and drops the upper neck.
- **Favourites and the best match reach over the list; rows shorten around them** (user: they should not avoid the list as their own components). Rows elide at the end, without a fade, using the arc circle and the divider as the limits, and they follow `presence` so the text gives way as the lobes bud.

## 2026-11-05 (compact taskbar, search on the burst)

- **Every interaction grows out of the taskbar, with the dashboard as the foundation** (user: one unified single system). Search now uses `Burst` like the dashboard instead of the two-lobe `Clash`; `Clash`, `Splash` and their tokens were removed, not shelved. Settings keeps its `Launch` for now (user: left alone).
- **Search is a full-height column, 20 % of the screen wide** (user: 100 vh, 20 vw), with the layout of the user's sketch: list on the left, favourites in a shelf off the top, the best match in a bulge, the field at the bottom. `Burst` gained `hasSteps` so the column has no notches.
- **The shelf and bulge are one drawn `Shape`, not goo-fused shapes.** Separate rounded shapes met the column at hard corners (the melt is too small to fillet them); one path with cubic S-curves gives the sketch's flowing wall. The necks stop at a `waist` past the column: returning to the column wall between shelf and bulge left a pointed notch on short screens.
- **The lobes are not part of `Burst`.** They are search's own layout, scaled from the burst's live width and their own `bud`, so `Burst` stays a generic body for the dashboard too.
- **The `...` pill is gone** (user). Its bar style and window mode choices already live in settings; its tray items have no home until the activity bar (`known-issues.md`).
- **Dragging the idle column compacts it** to power, audio and a dot (user). The gesture fires on travel (`Motion.fold.threshold` 24 px), not on release, and it is saved as `taskbar.compact` in `shell.json`, because it is a layout choice the user makes like the style.
- **The taskbar shrank 10 %** (user): every taskbar size token and the clock font scaled by 0.9 and rounded (thickness 52 → 47, items and idle circles 44 → 40, icon 26 → 23, glyph 20 → 18). The padding stays 4, since the pill length is computed from it separately from the thickness.

## 2026-11-05 (remaining motion as abilities)

- **Every host-driven timeline moved into an ability** (user go-ahead): `Launch` (settings), `Clash` (search), `Mutate` (task pills and idle circles, so the taskbar enter is their staggered `Mutate`s), `EdgePull` (edge reveal), `Jolt` (haptic bounce for the settings tab switch and the search strike). Hosts now only set state and bind to the ability's cues (`isOpened`, `isBudOut`, `isInnerShown`, `struck`, `landed`, `summoned`).
- **A `Behavior` that eases a property towards a state value counts as an ability**, not a host timeline: it is declared on the property and reacts to state. Overlay dim is such a `Behavior`, with the old delays as a `PauseAnimation` inside it.
- **Abilities without visuals are `QtObject`s** (`Press`, `Mutate`, `Jolt`), so they never take a slot in a positioner.
- **Jolt keyframes became tokens** (`Motion.settings.joltSteps`, `Motion.search.joltSteps`) and play linearly per step; the last settings step lost its OutQuad.
- **Not moved**: the taskbar carry (drag) choreography in `Taskbar.qml` (neck, closeness, ghost slots), which is interaction logic with `Carried` as its droplet. Right click has no animation yet.

## 2026-11-05 (dashboard bounce, edge lobe, leave through the taskbar)

- **The root side is a `Lobe`, not an `EdgeFuse` neck** (user: the whole left side merges with the edge like the search curve). The neck tokens are gone.
- **The explosion is a damped spring, not a clipped circle with cubic ease** (user: more punch, faster, bouncing the container out of the taskbar and back). The height leads the width so it stands up first, then the width overshoots and snaps back; wall surges are replaced by the spring's own overshoot. Spread 720 → 560 ms, converge 300 → 240 ms.
- **The leave hands the taskbar back at its start** (user: the dashboard becomes a smaller circle and moves off the screen while the taskbar appears in the same timeline), not after the ball has landed.
- **The leaving ball crosses into the taskbar's liquid** (user: it touches pills on the way out and they must react). Windows cannot goo across layers, so the ball's geometry goes through `Visibilities.visitors` (now `Overlays.visitors`) and the taskbar draws it for the exit slide; pills swell by closeness. The hand-off is skipped for the `bare` style, where the taskbar's liquid is invisible and the ball would vanish. Not verified in the preview.

## 2026-11-05 (dashboard burst from the edge)

- **The dashboard ball is born at the taskbar column, not the dashboard centre** (user: at the taskbar's x position, merged with the screen edge and the dashboard so it looks connected to the edge). The explosion is now one-sided: a circle from the seed clipped by the dashboard rectangle, so the root side meets its wall at once and the wave travels to the far wall, which crashes last. The root side gets no surge, crests or corner splashes because it is fused.
- **The edge connection is an `EdgeFuse` neck**, the same piece the fused taskbar style uses, kept while open rather than only during the ball, so the open dashboard still reads as hanging off the edge. Its height is a fixed token (`neck` 96), not the full root side, so it reads as a neck and not a fused wall.
- **The leave no longer flies**: the ball is already at the taskbar, so `flyBack` became `retreat` (narrow into an upright pill).

## 2026-11-05 (dashboard burst, abilities)

- **The dashboard enter is the settings motion, centred** (user: all pills and bars merge into one new circle in the middle, which must not exist before they merge, then it explodes and expands with liquid motion and waves crashing onto the walls). It replaces the gather-at-the-edge and push-in, which read wrong.
- **The explosion is a circle clipped by its walls, not a scale-up.** A uniform front hits the near walls first, slides along them and fills the corners last, so the crash order falls out of the geometry; surges and crests key off each wall's contact time, solved from the ease.
- **Animations are ability components** (user rule). New motion goes into an attachable component that plays from the element's state. `Press` replaced seven copies of the same press `Behavior`; `Burst` is the first overlay ability. Abilities stay flat in `components/`, not a subfolder: a `qs.components.abilities` module would import `qs.components` (for `LiquidShape`) while `qs.components` imports it back (`GlyphButton` uses `Press`).

## 2026-11-05 (overlays absorb the taskbar)

- **Every overlay swallows the taskbar** (user request: everything on the taskbar interacts, reacts and merges together). Search, settings and dashboard draw the taskbar's silhouettes in their own liquid and pull them in, instead of sliding over a taskbar they cannot goo with (it lives on a lower layer).
- **The taskbar geometry is edge-relative and the overlay mirrors it.** The old screen-coordinate handoff was computed while the taskbar window re-anchored after a side switch, so the settings ball flew back to the old side.
- **Settings merges into the gear and flies from there to the centre**; the hop along the edge to the middle is gone (user: do not move the full circle to the middle). The whole enter went from about 1.5 s to about 1 s.
- **Dashboard enter is the settings pattern**: gather into one pill at the edge, then push in from the side into its form. The pour-out wave and its idle ripple were removed at the user's request and shelved in `shelf/dashboard-wave/`, not deleted.
- **Rising bubbles are one shared component** (`components/Rising.qml`), used by the dashboard and the settings panel. Search keeps its own `Splash`, which also does jets and specks.

## 2026-11-05 (dashboard)

- **The dashboard follows the user's sketch** (given in chat): processor gauges, RAM/VRAM/disk rows, a divider, weather now and for 6 days, and an `[EMPTY]` slot for a later widget. It replaces the planned quick-settings grid (V/AS `13-dashboard.md`), which stays a later idea.
- **It pours out of the taskbar side as one wave**, not search's collision. No jets or specks (the user asked for no splashes). Bubbles rise from the surfaces to the screen edges.
- **The root is a clip line beside the taskbar, not the screen edge.** Liquid fused to the screen edge would cover the taskbar pills, because the overlay layer sits above the taskbar layer.
- **The wave is a sampled polyline, not cubic segments.** A travelling ripple on the top and bottom edges needs many segments; a polyline rebuilt per frame is simpler, and the goo blur hides the facets.
- **Opening**: a click on the taskbar clock, plus the `dashboard` shortcut and IPC. No key is forced; the README suggests `SUPER + A`.
- **Level colours are bands, not a gradient** (V/AS `06-level-and-waves.md`): cool blue, yellow, orange, red. The sketch's light blue is the cool band.
- **Weather is Open-Meteo** (no API key). The location is `weather.location`, geocoded by Open-Meteo, or, when empty, the IP lookup at ipinfo.io. It is fetched when the dashboard opens and the data is older than 15 minutes.
- **Hardware polls only while the dashboard is open**, every 1.5 s. GPU: NVIDIA through `nvidia-smi`, AMD through amdgpu sysfs; anything else shows `NO GPU`.
- **Icons are placeholder SVG paths in `Glyph`** (`cpu`, `gpu`, `memory`, `card`, `disk`, `umbrella`, `weather-*`) with a 2 px screen stroke (`Glyph.stroke`). Real icons come later.

## 2026-11-05 (liquid settings window)

- **Settings is a full-screen overlay layer per screen, not a `FloatingWindow`.** The gear flies from the taskbar across the screen and pours open into the panel, and the background dims and blurs like search. A floating window can neither draw outside its own rect nor be placed by the shell.
  - Rejected: keeping the floating window and animating only inside it, which loses the lift-off from the taskbar.
- **The whole taskbar becomes the settings liquid** (2026-11-05, replaces the lone gear droplet). The overlay redraws the taskbar's pills and idle circles from published rects and merges them into one ball, and the real taskbar is cut to opacity 0 in the same frame. It comes back only after the ball lands (`settingsAwayScreen`, `landed()`) with its own reveal pop.
  - Rejected: animating the merge inside the taskbar window, because the ball must then cross into the overlay window mid-flight, and the overlay blurs everything under it.
  - Parts are measured once on `settingsLaunching`, a signal emitted before the screens change, rather than bound every frame.
- **The morph is analytic, not simulated.** Each phase is a linear 0→1 value and the physics (stretch by velocity, damped wave, droplet flight) are closed-form functions of it, so any frame can be posed exactly in the preview and an interrupted open or close stays continuous (`leaveFrom` captures the current form).
- **Search and settings are exclusive**: opening one closes the other.
- **`CTRL + P` opens settings**, as the user asked. It is a compositor-global binding, so it shadows Ctrl+P inside apps; the README says how to rebind it.
- **Tabs**: Appearance (accent), Taskbar (side, style), Desktop (window mode, only where `Confinement.canConfine`). Style and mode stay in the `...` menu too.
- **Panel corners are a radius-30 rectangle inside the goo layer.** Blur + threshold rounds the corner join into a squircle-like curve, so no separate squircle path is needed.

## 2026-11-05 (settings, search tiles)

- **Search tiles have no container.** The app icon is the old tile size (`Appearance.search.tile` 83, 1:1) with the name below it (`search.label` 20). Selection scales the tile and turns the name accent. The best match is an icon filling the card height minus the name strip, with the name below; its description line and the `ENTER` hint are gone. The field no longer shows `RECENT`; it shows only the result count while searching.
- **The band grew to fit the names**: `innerHalf` 118→132, `outerHalf` 147→164 (same ratio), so the bottom row's names stay clear of the field.
- **Accent is a user setting**, default white `#ffffff` (was green `#5bfd5b`). `Appearance` reads `Config` (both are the config layer) instead of every module taking the accent as a property: it is a theme token used everywhere.
- **The colour wheel is a port of vados-notes `ColorPanel`**: conical hue gradient, white radial fade for saturation, a black overlay for value, a value slider, a swatch and a hex field. V/AS `components/03` forbids building a wheel on the web; Quickshell has no platform picker, so the native-sheet exception applies.
- **Right-edge taskbar by mirroring, not a second layout.** One transform on the module plus counter-flips on readable leaves, instead of rewriting every x in the taskbar for two edges. Idle expansions on the right grow left and read left to right, ending at their circle.
- **Project scratch scripts trip the V/AS style hook** when they carry markdown text (headings read as comments, articles as abbreviations). Docs are edited with Edit, not through generated scripts.

## 2026-11-05

- **driftwm is the primary target.** Hyprland and generic Wayland keep working.
  - All WM access sits behind `services/Compositor.qml`, so a new compositor is one backend branch.
  - Rejected: a separate service per WM imported by each feature. It leaks WM checks into every feature.
- **Only the active window hides the taskbar.** On an infinite canvas many windows overlap the left edge at once, so "any overlapping window" would keep the bar hidden for good.
  - Rejected: hide on any visible window (the old Hyprland rule).
- **Desktop mode minimizes by parking.** driftwm has no minimize, and `suspend` kills the client.
  - A parked window moves to `home + parkReach` at opacity 0, and its position is remembered.
  - Rejected: `suspend`, which loses app state.
  - Rejected: opacity alone, which leaves the window taking clicks and focus.
- **Desktop mode locks the camera by snapping it back** after each canvas change. The driftwm docs list no camera-lock option.
- **Search uses a liquid splash, not P5 fire sparks** (from the user's sketch).
  - Deleted: the fire Canvas (`Sparks.qml`).
  - Droplets live inside the goo layer, so they neck with the band.
  - A merge phase leaves one smooth band line after the collision.
- **Search content sits at the screen edges**: card on the left, favourites on the right, grid centred.
  - The view is 15% taller: tile 72→83, band halves 128/100→147/118.
- **Pill mutation is faster.** `Motion.pill` changes:

  | Token | Was | Now |
  |---|---|---|
  | pop | 90 | 60 |
  | spread | 170 | 110 |
  | leave spread | 160 | 105 |
  | leave pop | 200 | 130 |
  | fold | 160 | 105 |
  | slide | 240 | 160 |
  | size follow | 320 | 210 |
  | leave window | 80 | 55 |
  | stagger | 40 | 28 |

- **The taskbar backdrop fade is 35% narrower**: `Appearance.taskbar.backdropWidth` 240→156.
- **No comments in code** (V/AS rule). The header comments were removed from all QML and JS; what they said now lives in `architecture.md`, `quirks.md` and this file.

## Earlier (Hyprland era, 2026-11-04)

- **Fuzzy ranking.** Match tiers:
  - prefix: 1000
  - word-start substring: 820
  - substring: 640
  - subsequence: 300, plus bonuses

  Field weights: name 1, genericName 0.75, keywords 0.6, id 0.55.

  Final score = match + 45 × frecency, where frecency = log2(1 + launches) × 0.5^(hours / 168), so it halves each week.
- **Taskbar styles**: floating, fused and bare, switched live from the `...` menu.
- **Extension module**: an interactive pill (first: Wi-Fi) grows to full height and eats the rest of the taskbar. It is its own module (`modules/extension/`) hosted by `TaskbarWindow` next to `Taskbar`, because modules never import each other. The window maps `Taskbar.extensionRequested(key, origin)` to `Extension.extensionKey`/`origin` and binds `Taskbar.isEaten` to `Extension.isHolding`. Eaten parts leave through their own Mutate leave while the extension's liquid body grows from the pill's rect over them; they return once the body shrinks below `Motion.extension.handBack`. Corner radius is capped at `Appearance.extension.radius` so the tall body keeps room for rows. A new page is a component loaded by key in `Extension.qml`.
- **Hover opens idle pills**: hovering an expandable idle pill for `Motion.hover.openDelay` (150 ms) expands it like a click; leaving closes it after `Motion.hover.closeDelay`. Logic lives in `Taskbar.qml` (`hoverIdle`, `followPointer`), driven by the root `HoverHandler` point, because the expanded body lies outside the pill item. A safe triangle (apex: last pointer position inside the body; base: the far edge of the body, padded by `Appearance.taskbar.hoverSlack`) keeps it open while the pointer travels towards the far end; it closes after `Motion.hover.triangleGrace` of stillness in the triangle, or at once when the pointer leaves it. A click on a hover-opened pill pins it open (hover no longer closes it).
- **Dashboard content is clipped to the burst body**: `Dashboard.qml` wraps its content in `bodyClip`, a clipping item that follows `burst.form` (mirror aware), so parts still leaving never show outside the shrinking body. The clip is rectangular; the content sits inside the body corners.
- **The dashboard body has steps** (user, 2026-11-05, from a resize glitch they liked): a small step up on the top from the root to 70% of the width and a bigger one down on the bottom from the root to 42% (84 px, corner 64 px), which since 2026-11-05 is the notch holding the disk readout. The root lobe stretches over both steps so the edge curve has no corner where the step leaves it (user). On a laptop a third notch grows out of the far wall for the battery; it grows between the waves meeting and the end of the overshoot, landing with the pill's bounce (user: it appeared too late after the jet). They are plain rectangles in the liquid layer, so the goo fillets the inner corners for free instead of a hand-drawn outline. **The waves are one `Shape` bump each, not chained droplets**, because a chain of goo circles read as several waves; the bump is sampled along the wall path so it bends round the corner curve.
- **Dashboard gauges sit in a triangle** (user, 2026-11-05): GPU top left (`graphicsX`, with its VRAM bar), CPU top right (`processorX`), RAM below and centred between them (`memoryX`); ring 212, chip 128, centre text 20, row gap 4. The block height (258) keeps the bottom at about 547 px so the bottom step and disk notch did not move. The battery notch is 56 px deep so it reads as a bump, not a tab.

## Dashboard gauges pulled into the corner (2026-11-05)

GPU, CPU, RAM and the disk row moved toward the top-left empty space: `top` 48 to 24, `graphicsX` 56 to 20, `processorX`/`memoryX` shifted by the same 36 px; the battery sits 6 px (`battery.pull`) further into the body. Not re-rendered.

## Gauge name and caption inside the ring (2026-11-05)

`components/ArcText.qml` sets each character on the ring: the name along the top, the caption along the bottom, both facing inward and typed through `TypedText`. Gauge block height dropped to the ring plus 12 px. Disk row widened to 360. The battery vanished because `look` inside `Charge` resolved to the battery group; the pull is read through `dashboard.look`.

## Network graph under RAM (2026-11-05)

`services/Traffic.qml` samples `/proc/net/dev` all the time (one cheap file read a second) so the graph already holds 60 s when the dashboard opens; `ping` runs only while it is open, so ping and jitter start empty. Jitter is the mean absolute difference of the last 10 round trips. The graph scales to the 60 s peak times `headroom` 1.3 with a 1 Mbps floor. Not verified on Linux.

## Wall waves follow the steps (2026-11-05)

The crest ran along the plain body edge, hidden under the top and bottom steps (user: not visible on the steps). `Burst.wallTrack` now builds each side's outline as line and quarter-arc segments: along the step's outer edge, round its corner, down to the body edge, round the far corner, and around the battery notch when it has risen. `crestPath` samples that track by distance in one forward pass (`segmentPoint`), offsetting along each segment's outward normal.

## Activity pill (2026-11-06)

- **In the middle of the taskbar, not in the compact idle column** (user: it expands "from the center of the taskbar towards the right"). The roadmap had it opening from the compact column; the middle is the empty part of the bar and reads as a dynamic island. It is pushed down below a long task stack and up above the idle column.
- **Four states on a ladder** (user): hidden, idle, active, expanded. `CTRL + LEFT / RIGHT` step down / up and clamp at the ends rather than wrap, so holding a key lands on a known end. Data only nudges it (idle ↔ active when activities start or all stop), so a state the user forced stays.
- **Expanded grows from the spine towards the screen**: centred on the spine up to the capsule width, then the left side holds and the body spreads right. One body sized by one ability (`Reshape`) in the taskbar's own liquid, instead of a separate panel layer like the extension, so it necks with the taskbar pills it passes.
- **Each activity draws its own liquid on top of the shared body** (user: each module has its own expanded view): music a disc head with a progress ring, Discord two hanging drops for mic and deafen. A new activity is a key in `Activities.keys`, a face in `ActivityGlance` and an expanded view with its size in `Appearance.activity`.
- **Discord is detected from PipeWire, not an API**: a capture stream (`Stream/Input/Audio`) from Discord, Vesktop, WebCord, ArmCord or `WEBRTC VoiceEngine` means a call. Mic and deafen mute Discord's own streams, the only control a shell has; Discord's own mute icon does not follow.
- **Media counts as running while the player is not stopped**, paused included, so pausing from the expanded view does not fold it away.
