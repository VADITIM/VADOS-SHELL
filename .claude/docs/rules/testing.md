# Testing rules

Enforced by `tools/check-rules.py` where marked ✓.

- **Before every commit**: `python tools/check-rules.py` (hard rules, also a Stop hook) and `python tools/tests/run.py` (PySide6; Qt Quick tests in `tools/tests/tst_*.qml`). Both must pass.
- **Every engine has a test** ✓: Liquid, Overlays, Attention, Gesture, Burst, Lifecycle (and `Phases`), Geometry, Platform, StateFile, Confinement, Schema, Rendering (`LiquidLayer`, `Masked`, `config/Rendering.qml`), Log, Supervisor (and `Backoff`), Diagnostics, FrameDebug and Playing (the list is `ENGINE_TESTS` in `tools/check-rules.py`; a new engine joins it).
- **Every singleton service has a preview mock** ✓ (`tools/preview/mocks`), so every module stays previewable.
- **The whole preview loads without a single warning** (`tst_preview.qml`); a warning is a failure.
- **Transitions are tested under rapid input**: toggling a surface faster than its animations must end in a valid phase with nothing orphaned (`tst_burst`), and the move table is fuzzed (`tst_lifecycle`). A leave settled by the watchdog still lands, and leave geometry follows a screen change (`tst_burst`).
- **The frame budget is a test** (`tst_budget`, `rules/performance.md`); a change that pushes the search burst over it fails the suite.
- **A fixed bug gets a test that fails without the fix.** Check that it does by breaking the fix once.
- Fakes for Quickshell types live in `tools/tests/fakes` and follow the real API; when a fake and Quickshell disagree, the fake is wrong.
