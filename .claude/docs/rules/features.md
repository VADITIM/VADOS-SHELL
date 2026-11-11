# Feature rules

How a surface joins the shell (brief `Refactor.md`, 2026-11-10). Enforced by `tools/check-rules.py` (`[features]`) and `tst_features` where marked ✓; the rest is checked in review. The steps to add one are in `architecture.md` § Features; what is planned, and each planned feature's contract, in `roadmap.md`.

- **Every surface is a row in `utils/Features.js`** ✓. One row per line with `key`, `folder` (under `modules/`), `root` (the module's root type), `surface`, `origin`, `impact`, `needs`, `isBuilt`, and `layer` and `keepsTaskbar` on an overlay. Every folder in `modules/` belongs to a row and every row names an existing folder. A planned surface is a row with `isBuilt: false` and an empty folder; nothing loads it.
- **A row is built only when its surface is wired** ✓. `isBuilt: true` needs the root `modules/<folder>/<Root>.qml`. An overlay also needs `windows/<Root>Window.qml` with `overlayKey: "<key>"`, its `OverlaySlot` with the same key per screen in `shell.qml` (the window exists only while wanted) and an IPC target `<key>` in `Shortcuts.qml`; the lock needs `windows/LockWindow.qml` and `services/Lock.qml`; the desktop layer needs `windows/WidgetWindow.qml`. A folder that holds code while all its rows are planned fails.
- **Overlays come from the registry** ✓. `Overlays.kinds` is `Features.overlayKinds()`, the built overlay rows, never a second list. A planned overlay cannot open and never takes the taskbar.
- **The surface kind decides the host, the keyboard and the taskbar.** A feature picks one kind and takes everything in its row; a need the table does not cover is an engine change with a line in `decisions.md`, never a local exception.

| `surface` | Host | Keyboard | Taskbar | Enter and leave |
|---|---|---|---|---|
| `bar` | `TaskbarWindow` | none | is part of it | `Mutate` per pill |
| `mutation` | `TaskbarWindow`, drawn in the taskbar's liquid | none: pointer and wheel | stays; the surface grows out of one pill and back into it | `Mutate` and `Reshape` on that pill |
| `overlay` | an `OverlayWindow` | owns it while topmost (`Overlays.top`) | absorbed, then given back out of the surface; untouched when the row `keepsTaskbar` (the screenshot, whose frozen frame already shows it) | `Burst`, or another `Lifecycle` host |
| `lock` | `LockWindow` (`WlSessionLock`) | the lock's own | absorbed at the power pill | its own `Lifecycle`; unlocking never waits on it (`rules/security.md`) |
| `desktop` | `WidgetWindow`, below app windows, one per monitor | none | untouched; never hidden with it | `Turn` or `Mutate` per widget |
| `debug` | `FrameWindow` | while held | untouched | none |

- **Everything is born from the taskbar and returns to it** ✓. `origin` names the taskbar part a surface grows out of and collapses into: `column` (every part gathers into one circle at the taskbar column), `activity` (the activity pill), `idle` (the idle pill that was pressed), `power` (the power pill). A `mutation`, `overlay` or `lock` always has one; `bar` is `edge`; only `desktop` and `debug` are `none`. A new origin joins `Features.origins` with a line in `decisions.md`.
- **Impact decides how strong the motion is** ✓. `impact` is what the surface signals to the user, and its motion is never stronger than that. Each level above `ambient` has a ready budget in `Motion.budget.ready`: the longest time from the trigger to the first content of the surface. `tst_features` measures the shipped enter engines against it (`Burst.isOpened` for `focus`, `Mutate.isInnerShown` and the alert's `Reshape.isArrived` for `glance`); a new enter engine adds its measurement there. The settle after ready (bounce, waves, stagger) is not budgeted, but never blocks input.

| `impact` | Signals | Ready budget | Motion it may use |
|---|---|---|---|
| `ambient` | always there, never asks for attention | none: it does not enter on request | idle motion only, which stops under reduced motion |
| `glance` | a change in place, read in passing | `ready.glance` (250 ms) | the pill pop and spread (`Motion.liquid.pill`); no dim, the taskbar stays |
| `focus` | a surface the user asked for and now works in | `ready.focus` (700 ms) | the burst (`Motion.liquid.burst`, `crash`), a dim, rising bubbles |
| `takeover` | owns the whole screen and changes what the session is | `ready.takeover` (700 ms) | everything `focus` may, across the full screen, merged with the screen edges |

- **Modules inside a surface are catalogue rows.** A surface that holds modules lists them in one catalogue, and adding a module is one row and one file in the surface's folder, never a change to the surface's root logic: lock screen modules in `utils/Lock.js` (`modules`), settings tabs in `Settings.tabs` and `subTabsByTab` with a `Page` of `Piece`s, activities in `Activities.keys` with a face in `ActivityGlance` and an expanded `Activity<Name>`. A new surface with modules (widgets, alert sources, clipboard kinds) starts with its catalogue in `utils/` and a test.
- **A feature asks capabilities through `needs`** ✓. `needs` lists the `utils/Platform.js` capabilities without which the feature does not exist; it then shows nothing and its entry points do nothing. A feature that only loses a part without a capability keeps `needs` empty and degrades that part (`rules/compositor.md`). A capability no backend answers yet is added to `Platform.js` and the README table as `false` before a feature may need it.
- **A feature brings its whole contract with it.** In the same task as its first code: its settings keys (`rules/state.md`), its runtime state in a `StateFile`, a preview mock per service (`rules/testing.md`), a README Network row per file that reaches the network and an opt-in key for every system role it takes over (`rules/security.md`), a test for every new engine, a `Lifecycle` per surface (`rules/interaction.md`), and its section in the README. Then its row flips to `isBuilt: true` and its roadmap contract moves to `decisions.md`.
