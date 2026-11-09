# Changelogs

Newest version first. The version and its number are set by the user on each push.

## Unreleased

- Overlay leave to taskbar: the task pill's extension from circle to pill is faster and ends with a small bounce, with the program entries arriving at the same moment as before. The idle pills at the bottom keep the circle the overlay gave back and show their icons one after another instead of all at once (`Geometry.rebound`, `Motion.reveal.arrivalStagger`).
- Overlay enter: dashboard, search and settings content starts appearing earlier (around frame 22 for the dashboard, 27 for search): `Motion.burst.openShare` 0.45 → 0.14.
- Taskbar: the running-app indicator sits closer to its icon (`taskbar.indicatorInset`).
- Settings no longer draws its own clock: the taskbar's time and date stay put while settings is open. The squircle outline is closed, so the profile ring has no gap on its right side.
- Settings: every leave animation fits the page-swap budget so the next tab starts entering as the old one is gone; profile pictures (settings, search) are squircles (`Squircle`); the home banner is 1.5x larger.
- Settings open on a home page: the VAD/OS banner with the version below it (`config/Release.qml`); no tab is highlighted there. Reopening settings from Advanced no longer leaves its Link to VAD/OS page on screen, and the banner stays on a fixed-pitch grid without Space Mono.
- Profile: the tab's elements sit centred vertically. The swatch and hex field sit at the top left above the avatar; the colour wheel scale-rotate pops from the avatar's centre while the username untypes, then the value slider slides in from the left; closing plays it backwards.
- Settings: the section headline is gone, pages start at the top and the body ends a padding past the content. Profile: the GitHub name arrives with the bar sweep (`LabelReveal`), the history box no longer flips in, the accent label and reset button are gone, the hex field wipes in and types its hex, the empty last name types its placeholder instead of scaling.
- Profile tab redesigned from the mockup: avatar circle, username with last name, swatch and hex with a wheel that opens on click, GitHub name and a six month history frame whose border traces itself in, title types in and cells cascade in, edit mode (`ProfileEditor`); `ColorWheel` no longer holds the hex row.
- Every element of a settings tab enters on its own, staggered top to bottom, instead of the whole tab popping in at once (`Piece`, `Page`).
- Settings, Customization / Lock Screen: a 16 x 16 grid to place the lock screen modules (Time / Date, User Profile and Login Window are required; Weather, Music Player, Mini Dashboard and Notifications are optional), a scrollable grouped module list whose pills grow out of the body's right edge, and a wallpaper path. New keys `lock.layout`, `lock.wallpaper`. The lock screen itself is not built yet.
- Settings layout follows the user's sketch: a large centred section title with an underline above the content, the page content leaving 22% of the body free on the far side, and the clock at the bottom of the navigation column.
- Settings open with a full-screen liquid burst (the dashboard's), merged with the screen edges. The taskbar becomes the main navigation: an accent-coloured pop bar inside the body, with a white second pop bar to its right for Customization and Advanced. `Launch` and `Jolt` are removed.
- Settings restructured into User, Settings, Customization and Advanced. User saves name, second name, icon, GitHub and accent; Customization opens a second pop bar (Backgrounds, Pills, Taskbar, Lock Screen); Advanced holds the VAD/OS link note and the media player and notification daemon services. New keys `profile.secondName`, `profile.github`, `pills.opacity`, `pills.blur`, `pills.color`, `services.mediaPlayer`. Backgrounds and Lock Screen are placeholders until those features exist.

- Switching overlays no longer returns the taskbar for a moment: the new overlay is registered before the old one is closed.
- Switching between the dashboard and search no longer shows the taskbar mid-swap: the leaving overlay knows it hands over before it is closed, so it shrinks to the circle instead of streaming the taskbar parts back.
- Preview: search and dashboard are wired like the real overlay windows (swap wait, hand-over circle, phase reports), so switching between them no longer gathers the taskbar parts again mid-swap.

- Dashboard leave: content fades with the first part of the collapse (it showed outside the body), the top and bottom risers retract at once so the corners stay round and no vertical stem is left while the parts stream out.
- Switching between overlays (dashboard, search): the first one collapses into the circle at the taskbar column, the next one grows out of that same circle. The taskbar never appears in between, there are no two pills and no taskbar enter.
- Search leave: no wave runs on the leaving body (it cut arches at the wall corners), its content fades with the first part of the collapse, and released parts leave the ball gradually.
- Search open: a full-height body closes onto both screen edges as soon as its height is reached, whatever the wave and width overshoot do.

- Opening search or the dashboard: the taskbar parts start moving on the first frame, long parts (task pill, activity pill) first retract into a circle and then fly to the centre, and every part is swallowed as a circle. The spray droplets that shot out of the ball are gone. The body's top and bottom corners are round while it grows and then merge into the screen edge; the straight edge on the pill is gone.
- Closing search or the dashboard: all parts shoot out of the ball on the same frame, stop at their place without a bounce, the task pill starts stretching two frames before it arrives, and each part's icons play in the moment that part has arrived (idle pills first, then the activity pill, then the task pill) instead of all at the end.
- Frame-by-frame debugging: `KP_0` (IPC `frames toggle`) freezes every animation, shows `FRAME n` and the names of the playing animations top right, `UP` runs exactly one frame and `DOWN` goes back through the pictures kept of the last 120 frames. `KP_ADD` (IPC `frames shot`) copies a screenshot of the shell to the clipboard (`wl-copy`). Every top-level animation takes `paused: Motion.isHeld && running` (enforced by `tools/check-rules.py`); `Lifecycle` (`search burst`, `dashboard burst`, `settings launch`) and `Mutate` (`task pill`, `idle pill`, `activity pill`, `activity satellite`, `fold dot`) report what they play.
- Frame debugger: going back shows the frame sharp, at full resolution (it was half resolution, scaled up); the recording keeps up to 120 frames within 1 GiB. Stepping works over search too: overlays give the keyboard to the frame debugger while it holds, so the search field no longer swallows the keys.
- Playground: `Num 0` and `Num +` work everywhere, also in the search field; `+` copies the whole playground to the Windows clipboard (it only saved a file before), and the HUD is no longer baked into the replayed frames.
- `Motion.isHeld`: the one pause flag; the lifecycle watchdog waits while it is set.
- Closing the dashboard or search gives the taskbar back out of it: the body collapses into a circle at the taskbar column, the taskbar parts stream back out of it to their places (the task pill as a circle that stretches into the pill), and the taskbar takes over in place, its icons popping in at random. The taskbar no longer shows while the overlay is still leaving.
- The settings gear goes into the dashboard and search with the rest of the taskbar.
- The liquid draws again every time: the taskbar's pills come back after the dashboard or search closes, and the dashboard and search bodies appear on every open, not only the first. The layer's two colour surfaces were `layer.enabled` items that never drew again once switched off; they are now textures that stop updating instead.
- Activity pill in the middle of the taskbar: hidden, idle, active and expanded states, stepped with `CTRL + LEFT` / `CTRL + RIGHT` (IPC `activity next` / `previous` / `mode` / `rotate`), clicks and scroll. Music (MPRIS) and Discord voice calls (PipeWire) each have their own expanded shape.
- The activity pill merges into the dashboard and search burst without turning 90°: a taskbar part tips towards the seed only as far as it travels along its own length.
- Back from expanded to active, the pill's icons and satellite droplets each pop in on their own spot, one after another, instead of growing out of one point together.
- Dashboard and search curves are smooth: the burst samples its outline by distance instead of 8 points per span, samples its rounded corners, turns the wave round corners instead of jumping, blends the top and bottom waves into each other at mid-height, gives the trough a soft start, and antialiases the body.
- The search burst traces its outline about twice as fast (2.2 to 2.9 ms of script per frame, was 3.9 to 4.9 ms), back inside the frame budget.
- The burst wave skips the screen edges: search's full-height column no longer shows a crest along its top, bottom and root, and the dashboard's wave fades in as it leaves the taskbar edge.
- `Reshape` ability: a body grows to a new size with its own overshooting enter and a faster, separate collapse.
- Glyphs: music, headset, headphones, deafened, mic, mic-off, play, pause, next, previous.
- Preview: `Ctrl+Left/Right` step the pill, `Ctrl+Up` rotates the lead, `C` and `M` toggle the mock call and music.
- The activity pill runs on the engines: reduced motion reaches its reshape and bars, the cover art is masked through `Masked`, and its satellites and call drops no longer warn about stacking.
- Tests run on Windows (`tools/tests/run.py` passed a backslash path into QML).
- One logger (`utils/Log.js`): every message reads `vados: <subsystem>: <message>`, repeats within 5 minutes are counted instead of flooding the journal, and the last 100 entries are kept for diagnostics. IPC `diagnostics report` prints the compositor level, missing capabilities, overlay phases, background process restarts and the recent log.
- Background processes recover on their own (`services/Supervisor.qml`): the driftwm event stream, `nmcli monitor` and `udevadm monitor` (which never restarted before), `ping` and the weather requests restart with backoff (1 s doubling to 60 s) and log each failure and recovery; a failed weather fetch now retries instead of waiting 15 minutes.

- Compositor support is documented per backend (README "Compositor support") from one capability contract (`utils/Platform.js`): window minimize, snap, focus tracking, fullscreen detection and workspace management are now separate capabilities, and the `desktop maximize` / `fullscreen` IPC calls ask for window control. Hyprland no longer claims workspace support it never had.
- Layer boundaries are enforced: services hold no UI and import no higher layer, components import no services or state and take feature sizes from their module (`.claude/docs/interfaces.md`).
- Rendering quality: `rendering.quality: "lite"` drops the liquid's blur passes for weaker GPUs; shapes and outlines stay (`config/Rendering.qml`).
- Liquid layers render only while their surface is shown; the taskbar's empty title-tip layer no longer runs over the taskbar in the floating and fused styles. Effects and masks live only in the rendering components (`LiquidLayer`, the new `Masked`).
- `shell.json` is validated against one schema (`utils/Schema.js`): a wrong type or an unknown value falls back to its default and is reported once in the log (`vados: config:`), repaired values are written back, unknown keys are reported and ignored, and the settings refuse invalid values. The file now carries `version: 1`; files without one are migrated.
- New setting `rendering.quality` (`"full"` / `"lite"`).

- Overlays know each surface's phase (`Overlays.phaseOf`, `isSettled`): a screen whose overlays are all closed always gets its taskbar back, and an unplugged monitor closes its overlays instead of holding the keyboard.
- A leave cut short by the stuck-transition recovery still hands the taskbar back (it stayed hidden before) and clears the search field.
- A screen resized while the dashboard, search or settings is leaving reshapes the leaving body instead of drawing it in the old size.
- Faster search burst: its wall is traced once per frame instead of on every property change (script time per frame about halved). A frame budget test (`tools/tests/tst_budget.qml`) keeps it under 4 ms.

- Transition lifecycle (`components/Lifecycle.qml`, `utils/Phases.js`): the dashboard, search and settings bodies run explicit phases (idle, preparing, entering, active, exiting, recovering). Rapid toggling always ends in a valid state, and a transition stuck longer than 3 s settles and logs instead of leaving a half-open surface.
- Shared geometry (`utils/Geometry.js`) replaces the clamps, smoothsteps and splines copied across components.
- Compositor capabilities (`Compositor.capabilities`, `Compositor.level`): features ask what the compositor can do instead of which one it is; Desktop mode needs a free canvas and window control.
- Overlay engine (`state/Overlays.qml`, `windows/OverlayWindow.qml`) replaces `Visibilities`: one registry, layer exclusion, one keyboard owner, Escape closes the topmost. Fixes the empty taskbar when switching overlays, leaving balls overwriting each other, and the taskbar not returning on one screen when an overlay opened on another. IPC target `overlay`.
- Gesture engine (`components/Gesture.qml`): the fold drag, the edge pull and the task carry run on it.
- Attention engine (`state/Attention.qml`): which notifications may pop up (critical always, do-not-disturb, fullscreen, batching, own timeouts). `attention.doNotDisturb` in `shell.json`, IPC target `attention`.
- Persistence (`services/StateFile.qml`): versioned state files in `~/.cache/vados`. Desktop mode now remembers minimized windows across a shell restart instead of stranding them off-screen.
- Reduced motion: `motion.reduced` in `shell.json`, `Motion.pace`; transitions become instant and idle bubbles and splashes stop.
- Settings: a System tab with Motion (full, reduced) and Notifications (open, quiet).
- Reopening the dashboard or search while it is leaving now rewinds it instead of starting again from an empty ball.
- Hard rules are enforced by `tools/check-rules.py`; tests in `tools/tests` (`run.py`).
- Liquid engine: one shared physics for everything liquid. Springs are characters in `Motion.liquid` (`response`, `damping`, `expansion`) played by `utils/Liquid.js` (`rise`, `ring`, `arrival`, `pull`, neck merge and separation). The burst, the settings pop, the pill pop and the taskbar drag droplet now run on it, tuned to look as before.
- Liquid material thresholds are tokens (`Appearance.liquid`).
- Activity state (`state/Activity.qml`): what the activity bar shows and where it is open, merged from notifications and the tray.
- Notification service (`services/Notifications.qml`), off by default: `notifications.enabled` in `shell.json`, `Config.setNotificationsEnabled`.
- IPC targets `activity` and `notifications`; Hyprland global shortcut `vados:activity`.

## 0.1.1

- Search: the large circle shows the user's profile picture and mutates into the found app's icon while searching.
- Config: `profile.name` and `profile.picture` (`Config.setProfile`).
