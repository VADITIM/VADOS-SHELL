# Frontend rules

- **Tokens only.** Colours from `Appearance.color`, type from `Appearance.font` (Space Mono; labels in caps with `labelSpacing`), sizes from the per-feature `Appearance` groups. A raw hex or pixel size in a module is a bug.
- **Corners are squircle or fully round** (V/AS law 4). Pills use `radius: height / 2`.
- **The taskbar sits on the left or right edge** (`taskbar.side`, from settings) in one of three styles (`floating`, `fused`, `bare`), chosen in settings and saved to `shell.json`. There is no `...` pill. Taskbar code is written for the left edge only; anything readable inside it gets an `Upright` counter-flip bound to `host.isMirrored`. Its sizes were cut 10% on 2026-11-05 (thickness 47, items 40).
- **Dragging down on the idle pills compacts them** to power, audio and a small dot (bottom to top); dragging up, or pressing the dot, expands them again.
- **The activity pill sits in the middle of the taskbar with four states** (user, 2026-11-06): hidden (none), idle (visible, nothing happening), active (something running: Discord, Spotify), expanded (it spreads from the middle of the taskbar towards the screen into a bigger shape of its own; every module, Discord, Spotify and the rest, has its own expanded view). `CTRL + LEFT` / `CTRL + RIGHT` step through the states.
- **The accent is white by default and user-set** from settings. Selected and active state use `Appearance.color.accent`, never a fixed colour.
- **The search is one liquid body growing out of the taskbar edge** (user's sketches, 2026-11-05 and 2026-11-06): a base column 100% of the screen height and 20% of its width; favourites in a two-row grid at the top-left that scrolls and drags sideways, fading on the taskbar side and cut by the wall; the list below them, its rows fading and shrinking as they scroll up under the favourites; the best match as a large ringed circle at mid-height, beside the list, with its name in a pill outside the body; the field at the bottom.
- **The far wall keeps the drawn curve**: one smooth S-wave traced from the sketch (`Appearance.search.wall`), not steps, shelves or bulge lobes. Change the points only from a new drawing.
- **The best-match circle shows the user's profile picture while the field is empty and mutates into the found app's icon once the user searches** (2026-11-06); it falls back to the name's initial without a picture.
- **List rows beside the best match shorten** (name elided at the end) so text never runs under it; no fade there.
- **App entries have no container**: the icon itself is the tile (1:1) and the name sits below it. No hint labels (`ENTER`, `RECENT`).
- **Overlays dim the screen**; blur is the compositor's job (Hyprland `layerrule`, driftwm window/layer rules).
- **Text arriving on screen uses the V/AS reveal** (`TypedText`, `Turn`), not a plain fade.
