# Subsystem interfaces

Who owns each layer, what it may import, what it offers the layers above, and who may call it. Derived from the code (2026-11-07, `direction.md` Phase 1). `tools/check-rules.py` enforces the import columns (`[layers]`, `LAYER_IMPORTS`) and the component token list (`COMPONENT_TOKENS`); the rest is review. Change this file in the same task as the interface.

Data flows down, events flow up: `config → services → components → modules → windows → shell.qml`. `state/` is the only sideways channel; `keybinds/` only flips state or calls a service.

| Layer | Owns | May import (`qs.*`) | Must not import | Called by |
|---|---|---|---|---|
| `config/` | User settings, design and motion tokens | nothing from `qs` | every other layer | everyone (modules read only `Appearance`, `Motion`, `Rendering`) |
| `utils/*.js` | Pure logic with tests, no QML types (`Log.js` alone keeps state: the log ring) | other utils | everything | every layer, by relative `import "../utils/X.js"` |
| `services/` | System and compositor data, no UI | `config`, other services | `state`, `components`, `modules`, `windows`, `keybinds`; any visual type or UI import ✓ | modules (data), state, windows (activation), keybinds |
| `state/` | Shared UI state across features and screens | `config`, `services` | `components`, `modules`, `windows`, `keybinds` | windows, keybinds, `shell.qml` |
| `components/` | Feature-agnostic visual and interaction primitives | `config` (component token groups only ✓) | `state`, `services`, `modules`, `windows`, `keybinds` | modules, tests |
| `modules/` | One user-facing feature each | `config` (`Appearance`, `Motion`), `services`, `components`, `state` | `Quickshell`, `Config`, another module, `windows`, `keybinds` | windows |
| `windows/` | Layer-shell hosts, one per screen | everything below | `keybinds` | `shell.qml` |
| `keybinds/` | Global shortcuts and IPC entry points | `config`, `services`, `state` | `components`, `modules`, `windows` | the compositor (shortcuts), `qs ipc call` |
| Compositor adapter | `services/Compositor.qml` + `utils/Platform.js` | `Quickshell.Hyprland`, `hyprctl`, `driftwm msg` (nowhere else ✓) | | services (`Confinement`, `Occupancy`), `state/Attention`, keybinds |

## config

- `Config` (`config/Config.qml`): `data.<group>.<key>` (the `JsonAdapter` over `shell.json`, schema in `utils/Schema.js`) and one setter per key: `setTaskbarStyle`, `setTaskbarSide`, `setTaskbarCompact`, `setAccent`, `setWindowMode`, `setWeatherLocation`, `setReducedMotion`, `setRenderQuality`, `setDoNotDisturb`, `setNotificationsEnabled`, `setProfile`, `toggleFavorite`. Only windows, keybinds, services and state read it; modules get values as properties and send changes up as signals.
- `Appearance`: sizes and colours. **Component-level groups** (any component may read them): `unit`, `radius`, `color`, `font`, `liquid`, `rising`, `burst`. **Feature groups** (only the feature's module, its window, or a service of that feature): `taskbar`, `extension`, `settings`, `desktop`, `dashboard`, `search`. A component that needs feature sizes takes them as a `look` property.
- `Motion`: timing and physics, and `pace(duration)`, the reduced-motion precedence. **Component-level**: `isReduced`, `pace`, `stateDuration`, `hoverIn`, `hoverOut`, `press`, `pill`, `type`, `gesture`, `lifecycle`, `burst`, `rising`, `liquid`. **Feature groups**: `highlight`, `alerts`, `extension`, `tip`, `hover`, `fold`, `reveal`, `carry`, `settings`, `desktop`, `dashboard`, `search`, plus `budget` (`frame`, `sampleShare`, and `ready` by impact: `glance`, `focus`, `takeover`), `store`, `attention`, `supervision` for tests, `StateFile`, `Attention` and `Supervisor`. A component that needs feature timing takes it as a `pace` property.
- `Rendering`: `isLite`, `blur(radius)` (render quality for the rendering components).

## utils: the feature registry

`utils/Features.js` (`rules/features.md`, `architecture.md` § Features): `surfaces`, `origins`, `impacts` (the allowed values), `features` (one row per surface, built or planned) and `overlayKinds()` (key → `{ layer }` for the built overlay rows). Read by `state/Overlays.qml` (`kinds`), `tools/check-rules.py` (`[features]`) and `tst_features`. A module's root named in a row is the interface its window binds (§ modules).

`utils/Alerts.js` (`architecture.md` § Alerts): the alert source catalogue `sources` (`key`, `label`, `glyph`, `tint`, `ids`), `generic`, `glyphs`, and `identify(appName, desktopEntry)`, `plainOf(text)`, `clip(text, limit)`, `leadOf(notifications)`. Read by `modules/alerts/Alerts.qml` and `tst_alerts`. The tints are brand colours, data of the catalogue rather than theme tokens.

## services

Singletons with no UI. Public members other layers use (the rest is internal):

| Service | Interface | Used by |
|---|---|---|
| `Compositor` | `capabilities`, `level`, `activeWindow`, `lastWindow` (the window that had focus last and is still open; driftwm checks it is still open, other backends keep the last active one), `focusedScreen`, `canvasState`, `viewports()`, `isListed(value, id)`, `send(arguments)`, `action(spec)`, signal `canvasChanged` | `Confinement`, `Occupancy`, `Attention`, `Shortcuts` |
| `Confinement` | `canConfine`, `isConfined`, `canMinimize`, `canSnap`, `parked`, `isParked(id)`, `activate(toplevel)`, `minimize()`, `maximize()`, `fullscreen()`, `snap(direction)` | `Toplevels`, `SettingsWindow`, `Shortcuts` |
| `Occupancy` | `isCovered(screenName, isHolding)`: the active window, or with `isHolding` and no window focused, `Compositor.lastWindow` | `TaskbarWindow`, `OverlayWindow` |
| `Toplevels` | `groups`, `iconFor(appId)`, `activate(group)`, `close(group)` | taskbar module |
| `Apps` | `search(query)`, `recent()`, `byId(appId)`, `launch(appId)` | search module |
| `Audio` | `isReady`, `volume`, `isMuted`, `setVolume(value)`, `toggleMute()` | taskbar module |
| `Battery` | `isPresent`, `level`, `isCharging`, `secondsLeft` | taskbar, dashboard |
| `DateTime` | `time`, `date` | taskbar |
| `Hardware`, `Traffic`, `Weather` | readings, plus `isActive` (polls only while a window sets it) | dashboard module; `DashboardWindow` sets `isActive` |
| `Processes` | `groups`, `historyRows`, `diskRate`, `isActive`; `kill(row)`, `open(row)` (uses `Toplevels`), `find(row)` | dashboard `TaskManager`; `DashboardWindow` sets `isActive` |
| `Network` | `isEnabled`, `isWired`, `isConnected`, `ssid`, `strength`, `networks`, `isWatching`, `toggle()`, `connectTo(name)` | taskbar, extension |
| `Notifications` | `isServing`, `list`, `latest`, `unreadCount`, `hasUnread`, `isUrgent`, `isCritical/isLow/isAlive(n)`, `history`, `historyLimit`, `forget(entry)`, `openEntry(entry)`, `markRead()`, `dismiss(n)`, `clear()` (history too), `open(n)` (default action, else the desktop entry), `invoke(n, id)`, signal `received` | `Activities`, `ActivityState`, `Attention`, `Shortcuts`, `TaskbarWindow`, taskbar module |
| `Power` | `lock()`, `suspend()`, `restart()`, `shutdown()` | taskbar |
| `Removable` | `devices`, `eject(device)` | taskbar |
| `FileChooser` | `isPicking`, `choose(title, kind, onChosen)` (false while one is open) | `Transfer`, `SettingsWindow` (profile picture) |
| `Transfer` | `installed`, `appKey`, `appName`, `isAvailable`, `isPicking` (`FileChooser`), `devices`, `nextApp()`, `send(peer)` | notifications module, `NotificationMenuWindow` |
| `Clipboard` | `isEnabled`, `size`, `isKeepingImages`, `entries`, `pick(entry)` (copies it again through `wl-copy`), `togglePin(entry)`, `remove(entry)`, `clear()` (keeps pinned) | `ActivityState`, `TaskbarWindow`, `Shortcuts` |
| `Tray` | `items`, `open(item, window, x, y)`, `openMenu(item, window, x, y)` | `Activities`, taskbar module (`ActivityTray`) |
| `StateFile` (type) | `name`, `version`, `defaults`, `values`, `isLoaded`, `update(next)`, `flush()` | services that keep runtime state |
| `Supervisor` (type) | `name`, `isActive`, `process`, `status`, `failures`, `restarts`, `lastFailure`, `fail(reason)`, `succeed()`, signal `restarted` | `Compositor`, `Network`, `Removable`, `Traffic`, `Weather` |
| `Supervision` | `supervisors`, `enroll(supervisor)`, `release(supervisor)` | `Supervisor`, `Shortcuts` (IPC `diagnostics`) |

## state

| Singleton | Interface | Used by |
|---|---|---|
| `Overlays` | `kinds` (from `Features.overlayKinds()`), `top`, `taskbarParts`, `isOpen(key, screen)`, `isWanted(key, screen)` (open or not idle yet: its window must exist), `isHolding(screen)` (an overlay is open or still moving there), `ownsKeyboard(key, screen)`, `isTaskbarAway(screen)`, `visitorOn(screen)`, `open/close/toggle(key, screen)`, `closeTop()`, `reportPhase(key, screen, phase)`, `returnTaskbar(screen)`, `placeTaskbarParts`, `placeVisitor`, `keepScreens(names)`, signal `taskbarGathering(screen)` | windows, `Shortcuts`, `shell.qml` |
| `ActivityState` | `modes`, `mode`, `screenName`, `lead`, `leadKey`, `isAnyLive`, `isReading`, `modeOn(screen)`, `set(screen, mode)`, `step(screen, direction)`, `rotate(direction)`, `toggle(screen)`, `fold()`, `pin(key)` (expanding with the bell as lead opens the `notifications` overlay), `clipboardScreen`, `canClipboard`, `isClipboardOn(screen)`, `toggleClipboard(screen)` (folds an expanded pill first), `closeClipboard()` (expanding and stepping close it) | `TaskbarWindow`, `Shortcuts`, preview |
| `FrameDebug` | `isActive`, `isStepping`, `isSnapping`, `isViewingPast`, `counter`, `shownLabel`, `frame`, `history`, `cursor`, `memory`, `screenName`, `shotsOn(screen)`, `toggle(screen)`, `begin(screen)`, `step()`, `back()`, `snap(screen)`, `finishSnap()`, `close()`, `refresh()`, `expect()`, `store(token, shot)`, `skip()`, signals `captureRequested(token, scale)`, `snapshotReady(shots)` | `FrameWindow`, `FrameTap`, `Shortcuts` |
| `Attention` | `isQuiet`, `isFullscreen`, `peek`, `held`, `mayPeek(n)`, `dismissPeek()`, `setQuiet(isOn)` | `Shortcuts`, `TaskbarWindow` |

## components

Reusable, feature-agnostic primitives. They read only component-level tokens; feature sizes and timing arrive as properties (`look`, `pace`). Abilities (`architecture.md` § Abilities) are attached to a host that only sets state.

- Engine: `Lifecycle` (`send(event)`, `phase`, signals `moving`, `moved`, `interrupted`), `Gesture` (signals `moved`, `crossed`, `thrown`, `tapped`, `ended`), `Burst` (overlay enter/leave; `isShown`, `parts`, `phase`, `isActive`, `isOpened`, signal `landed`), `Gather`, `Mutate` (`isArriving`, `hasArrived`), `Turn` (`isFlipping`, `flipAngle`, `spinAngle`), `LabelReveal` (`isShown`, `sweepWidth`, `label`), `Squircle` (`color`, `strokeColor`, `strokeWidth`), `TypedText` (`leaveBudget`), `Gulp` (`isLanded`, `amplitude`, `span`, `swell`), `Reshape` (`shrinkLag`, `shrinkEasing`, `windUp`, `shrinkArriveShare`), `Outline` (`isShown`, `radius`, `traceDuration`, `leaveDuration`, `label`), `Press`, `Rising`.
- Rendering: `LiquidLayer` (`isShown`, `shapes`), `LiquidShape`, `LiquidBridge`, `EdgeFuse`, `Lobe`, `Masked`, `Surface`.
- Controls and text: `GlyphButton` (signal `clicked`), `Glyph` (`name`, `level`, `isCharging`; the icon from `utils/Icons.js` `pick`), `ColorWheel` (requires `look`; `diameter`, `wheelShare` for the wheel's scale-rotate pop, `sliderShare` for the value slider's left-to-right slide; signal `picked`), `EdgePull` (requires `look`, `pace`; signal `summoned`), `TypedText`, `ArcText`, `Upright`.

## modules

Each module's root is the interface its window binds: state comes in as properties, requests leave as signals.

| Module | In (properties) | Out (signals) |
|---|---|---|
| `Taskbar` | `isCovered`, `isSummoned`, `barStyle`, `isCompact`, `isMirrored`, `isAway`, `isVeiled`, `isEaten`, `visitor`, `hostWindow`, `isAlerting`, `alertSize`, `isClipboardOpen`, `clipboardSize` | `compactRequested`, `settingsRequested`, `dashboardRequested`, `extensionRequested`, `clipboardCloseRequested`; reads `isRevealed`, `isArriving`, `hasArrivedAt(centerY)`, `inputWidth`, `liquidParts()`, `alertRect`, `isAlertShown`, `clipboardRect`, `isClipboardShown`, `isClipboardBumpHovered` |
| `ClipboardHistory` | `isMirrored`, `entries`, `body` (the pill body rect), `isBodyShown`, `isBumpHovered` | `pickRequested(entry)`, `pinRequested(entry)`, `removeRequested(entry)`, `clearRequested`, `closeRequested`; reads `bodySize` |
| `Alerts` | `isMirrored`, `peek`, `body` (the pill body rect), `isBodyShown` | `dismissRequested`, `openRequested(notification)`; reads `bodySize`, `source`, `slide` |
| `Extension` | `isMirrored`, `inset`, `extensionKey`, `heldKey`, `origin` | `closeRequested`; reads `inputWidth` |
| `Search` | `isOpen`, `favoriteIds`, `profileName`, `profilePicture`, `parts`, `isMirrored`, `canHandOff` | `closeRequested`, `landed`, `favoriteToggled`; reads `isPresent`, `phase`, `visitor` |
| `Dashboard` | `isOpen`, `isMirrored`, `parts`, `canHandOff` | `closeRequested`, `landed`; reads `isPresent`, `phase`, `visitor` |
| `Settings` | `isOpen`, `parts`, `accent`, `taskbarSide`, `barStyle`, `windowMode`, `canSwitchMode`, `isReducedMotion`, `isQuiet` | `closeRequested`, `landed`, `accentRequested`, `sideRequested`, `styleRequested`, `modeRequested`, `reducedMotionRequested`, `quietRequested`; reads `isPresent`, `phase` |

Search and dashboard read `Appearance.taskbar.margin`: they grow out of the taskbar column, so the taskbar's margin is their root.

## windows

`TaskbarWindow` (per screen, `WlrLayer.Top`), `FrameWindow` (per screen; the frame debugger, outside `Overlays`) and the `OverlayWindow`s (`SearchWindow`, `SettingsWindow`, `DashboardWindow`, `NotificationMenuWindow`; `overlayKey`, `isOpen`, `parts`, `canHandOff`, `phase`, `requestClose()`, `land()`, `placeVisitor()`). Windows are the only place that bridges `Config` setters to module signals and reports overlay phases to `Overlays`. Created only by `shell.qml` through `Variants`: the taskbar and frame windows directly, each overlay window inside an `OverlaySlot` (`overlayKey`, the window as its default `surface` component, `isWanted`, `isLoaded`), which builds it when `Overlays.isWanted(key, screen)` and destroys it when it is closed, idle and no longer `isPresent`. An `OverlayWindow` is therefore always built closed: `isOpen` stays false until the window is complete (`isComplete`), so its module sees the same closed-to-open change as before.

## keybinds and IPC

`keybinds/Shortcuts.qml`: global shortcuts `vados:frames`, `vados:frameShot`, `vados:search`, `vados:settings`, `vados:dashboard`, `vados:activity`, `vados:notifications` (opens the notifications menu; Hyprland protocol), and `qs ipc call` targets `frames` (`toggle`, `step`, `back`, `shot`, `close`, `status`), `dashboard`, `search`, `settings`, `desktop`, `overlay`, `activity`, `attention`, `diagnostics`, `notifications`. Each handler flips `state` (`Overlays`, `ActivityState`, `Attention`), calls a `Config` setter, or calls a service (`Confinement`, `Notifications`). No feature logic.

## Compositor adapter

`services/Compositor.qml` is the only file that knows which compositor runs. It publishes `capabilities` (`utils/Platform.js`, one row per backend) and `level` (`core`, `extended`, `native`). Everything else asks a capability:

| Capability | Asked by |
|---|---|
| `windowControl` | `Compositor.send` (commands go nowhere without it), `Confinement.maximize`, `Confinement.fullscreen`, `Confinement.canConfine` |
| `freeCanvas` | `Confinement.canConfine` → settings mode buttons (`canSwitchMode`), Desktop mode |
| `windowMinimize` | `Confinement.canMinimize` → `minimize()` |
| `windowSnap` | `Confinement.canSnap` → `snap()` |
| `activeWindow`, `windowGeometry`, `fullscreenDetection` | published as `activeWindow`; `Occupancy` hides the taskbar and `Attention` holds notifications from it |
| `focusTracking` | published as `focusedScreen` (the first screen without it) |
| `workspaceManagement` | nothing yet; no backend has it |
| `layerShell` | required by the shell itself |

The README section "Compositor support" lists the same table with what degrades; `tools/check-rules.py` fails when it and `Platform.js` disagree.
