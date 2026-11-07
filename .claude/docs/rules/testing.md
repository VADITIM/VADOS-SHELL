# Testing rules

Enforced by `tools/check-rules.py` where marked ✓.

- **Before every commit**: `python tools/check-rules.py` (hard rules, also a Stop hook) and `python tools/tests/run.py` (PySide6; Qt Quick tests in `tools/tests/tst_*.qml`). Both must pass.
- **Every engine has a test** ✓: Liquid, Overlays, Attention, Gesture, Burst, StateFile, Confinement (the list is `ENGINE_TESTS` in `tools/check-rules.py`; a new engine joins it).
- **Every singleton service has a preview mock** ✓ (`tools/preview/mocks`), so every module stays previewable.
- **The whole preview loads without a single warning** (`tst_preview.qml`); a warning is a failure.
- **A fixed bug gets a test that fails without the fix.** Check that it does by breaking the fix once.
- Fakes for Quickshell types live in `tools/tests/fakes` and follow the real API; when a fake and Quickshell disagree, the fake is wrong.
