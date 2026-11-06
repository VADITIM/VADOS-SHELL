# Quirks

- **`long` is a reserved word in QML JavaScript.** `const long = …` makes the file fail to parse, and `qmlformat` exits 1 without a message.
- **The preview harness cannot time animations.** `grabWindow` under the basic render loop lets every animation finish within one frame, and the threaded loop stalls while grabbing. Check motion by setting the phase properties by hand and grabbing poses.
- **The dashboard body uses per-corner `Rectangle` radii** (`topLeftRadius` and friends), which need Qt 6.7 or newer.
- **A Quickshell window's `visible` reads `false` while it is being created.** The getter switches from the requested value to the backing window's `isVisible()` as soon as the backing window exists, before it is shown. `onVisibleChanged: if (!visible) close()` therefore closed the settings window during its own creation, and the `LazyLoader` destroyed it before it appeared. Use `onClosed` instead (the old floating settings window hit this): it fires only when the user, the compositor or an error closes the window, never on creation or on a programmatic hide.
- **Unverified Quickshell assumption (settings, 2026-11-05):**
  - Changing `PanelWindow.anchors` at runtime (taskbar side) re-anchors the layer surface without a restart.
- **The fold gesture fires mid-drag, once per press.** Folding hides the pressed idle, whose `FoldDrag` is then disabled and cancelled, so waiting for the release would never fire. `hasFolded` also swallows the click a kept idle (audio, power) would get on release.
- **Preview: slow motion by patching the built `Motion.qml`.** Multiplying `burst.converge`, `spread`, `impact` and `leave` in the build tree before loading `play.qml` makes timed `grabWindow` frames usable for the burst (scratch `shot.py`, 2026-11-05).
- **The input mask is not inside the mirrored module.** `Region { item }` mapping through an item transform was not trusted, so `TaskbarWindow` places its own `inputZone`.
- **Preview: `QQmlExpression` cannot see singletons** imported by the preview root (`Appearance`, `Config` evaluate to undefined). Read values through a root child (`settings.accent`) instead. Build the expression on `QQmlEngine.contextForObject(window)`, not `engine.rootContext()`, or ids are undefined too.
- **`long` and `short` are reserved words in the QML parser**, even as JavaScript `const` names. `qmlformat` then fails with no message.
- **Preview: `PySide6.scripts.qml` imports every `.py` file next to the QML file it runs.** Keep preview QML drivers in a folder without Python scripts, or one of them may create a second application.
- **Preview: large liquid layers drop to about 1 fps**, so animations jump to their end. Judge the settings morph from posed values (set `merge`, `hop`, `shoot`, `pop`, `bud`, `extend`, or `leaveFrom` + `isLeaving` + `collapse`/`back`, on a `Settings` whose `isOpen` stays false), not from timed screenshots.
- **Unverified Quickshell assumption (settings morph, 2026-11-05):** the gear origin assumes `ShellScreen.width` and the taskbar window's `width` share logical pixels, so a right-edge origin lands on the gear. Check on a scaled output.

- **Fuzzy subsequence noise.** "fire" matched "LibreOffice Writer" through scattered letters. A subsequence is now rejected when more than ceil(length / 2) of its letters are scattered (`Fuzzy.match`).
- **The search grid scrolled when the second row was selected.** Cell height plus gap was taller than the view. Fix: tiles fill the whole cell (tile + gap), and the GridViews are offset by -gap/2.
- **Tiles select only on real mouse movement** (`onPositionChanged`). Otherwise the tile under a resting cursor steals the keyboard selection whenever the results change.
- **FoundCard swaps content through an inner `Turn`.** `shownApp` changes only after the old face has left (`onDeparted`), so the flip never shows the new app on the old face.
- **Preview typing.** `QTest.keyClicks` does not accept a QQuickWindow. Use `QTest.keyClick(window, character)` per character.
- **Goo hides tiny shapes.** A shape smaller than about the blur radius never crosses the threshold on its own.
  - `LiquidLayer` also draws the raw shapes, so small droplets still show, but without a rim.
- **Unverified driftwm assumptions.** Nothing here has run on driftwm yet (as of 2026-11-05). Check these first when Desktop mode misbehaves:
  - Per-output `camera` is the viewport centre, Y-up.
  - Window `position` is the frame centre.
  - `fullscreen` and `pinned` in `state` hold window ids in some shape. `Compositor.isListed` accepts a number, an array or an object.
  - `move` accepts negative numbers as positional arguments.
- **Custom `top`, `bottom`, `left` or `right` properties fail on any `Item`** ("Cannot override FINAL property"): they are the anchor lines. `Wave` and `Bubbles` use `ceiling`, `floor`, `fromX`, `toX`.
- **The code-style hook reads regex literals as abbreviations** (flags like `/g`, escapes like `\s`). Build regexes with `new RegExp("...")` from strings, as `Hardware.qml` does.
- **Unverified on Linux** (dashboard): `FileView` reloading the size-0 `/proc/stat` and `/proc/meminfo`, the hwmon names (`k10temp`, `coretemp`, `zenpower`, `cpu_thermal`), the `nvidia-smi` field order, amdgpu `gpu_busy_percent`, and `XMLHttpRequest` from a Quickshell singleton.
- **Hyprland's `GlobalShortcut` does nothing on other compositors.** Bind the IPC call instead (see README).

- **Taskbar selection circle must not use pause steps.** `TaskPill.slideWash` runs twice per activation (`onActiveTaskChanged`, `onWashTargetTopChanged`, in either order). A `PauseAnimation` plus move per edge made moving down snap instead of slide; each edge is now one `NumberAnimation`, the trailing edge longer by `Motion.highlight.trail`. Unverified on the Linux shell as of 2026-11-05.
- **Hover leave can fire before the next hover enter.** Moving up the taskbar, the old `TaskItem` reports leave first, so `hoveredTask` briefly becomes null and the name pill reset; moving down the order is reversed. `Taskbar.tipGrace` (`Motion.tip.grace`) delays hiding the pill so the next enter takes over. Unverified on the Linux shell as of 2026-11-05.
- **The selection circle never resets or snaps once placed.** `TaskPill.slideWash` used to forget its position whenever no task was active (focus passes through that state when switching) and snapped for a same-task retarget, so the next activation teleported. It now keeps its last position and always slides to the new target; it snaps only on first placement or while items are hidden. Unverified on the Linux shell as of 2026-11-05.

- **Extension body is a separate liquid layer from the taskbar's.** It does not neck with taskbar pills, so the hand-over relies on the pill leaving as the body grows from its rect. Unverified on the Linux shell as of 2026-11-05.
- **Wi-Fi list reloads reset the `ListView`.** `Network.readNetworks` rounds strength to 0.1 and assigns `networks` only when the JSON differs; rows already shown snap to present (`isSettled`) instead of replaying the enter. Polls every 8 s only while the page is open (`Network.isWatching`). Unverified on the Linux shell as of 2026-11-05.
- **The extension closes on pointer leave** (`Motion.extension.linger`), on the close button, or when an overlay takes the taskbar away.

- **The taskbar stays visible for `Motion.pill.awayHold` after an overlay takes it away** (`isVeiled` timer in `Taskbar.qml`). Its liquid layer hides at once, because the overlay draws the merging silhouettes, while the inner elements (icons, glyphs, clock) play their own `Turn` leave (rotate and shrink) instead of vanishing. Unverified on the Linux shell as of 2026-11-05.
- **`PathArc` picked the wrong circle in the old search wall** (the wall is now a sampled spline inside `Burst`; kept for any future arc). With the same endpoints and radius, its `useLargeArc` / `direction` flags did not map to the visual sweep we expected (Qt 6, CurveRenderer, preview); the bulge drew on the far side of its chord. The wall uses `PathAngleArc` with explicit centre, start angle and sweep (clockwise positive, Y down) and `moveToStart: false`.
- **An `Item` property named `left` cannot be declared** (Qt 6 reports "Cannot override FINAL property" and the whole module type becomes unavailable; the preview harness only shows it when `engine.warnings` is printed).
- **The favourites mask uses the wall outline from the screen edge, not the liquid wall's fill.** The liquid wall fill starts inside the burst column, so masking with it would hide the favourites over the column. `wallMask` draws `burst.wallOutline` from `-wallOverhang` (`maskOutline`). It is a hidden `layer.enabled` item; untested on Linux.
- **The search wall's crest is mostly off screen along the top and bottom.** At full size the body's top and bottom edges are the screen edges, so the crest only shows on the root flare, the wall's flares and the wall itself.
- **Quickshell's `MprisPlayer.position` does not notify by itself.** `Activities` calls `player.positionChanged()` every `Motion.activity.tick` while playing. Unverified on Linux.
- **Unverified on Linux** (activity pill): Discord's PipeWire stream names and `media.class` values, that `PwObjectTracker` over every stream node is enough to read `properties`, that muting those streams works while Discord holds them, Spotify's `identity` string.
- **The preview's mock `Singleton` is a `QtObject` with no default property**, so a state singleton cannot hold `Connections` or `Timer` children there. `ActivityState` reacts through a mirrored property (`isAnyLive`) and its change handler instead.
