# Performance rules

Checked in review and with the preview; ✓ is enforced by a test. The shell must cost nothing while idle.

- **Idle costs nothing.** No `FrameAnimation`, `Timer`, process or poll runs while its surface is hidden: services poll only while a window sets `isActive` (`Hardware`, `Traffic`, `Weather`), abilities stop their frame loops when inactive (`Rising.isActive`, `Burst.isActive`), overlay windows are invisible while not present.
- **Frame budget** ✓: script work per frame stays under `Motion.budget.frame` (4 ms) for `Motion.budget.sampleShare` (95%) of frames during the heaviest animation (the search burst, opening and leaving), measured by `tools/tests/tst_budget.qml` (best of three sweeps, bindings and `trace()` together). It measures script only, offscreen; render cost on real hardware is not measured yet. Geometry that depends on several changing values is traced once per frame through `Qt.callLater`, never as chains of bindings over arrays (the burst's wall outline moved into `trace()` for this, 2026-11-07).
- **Liquid layers exist only while shown.** A `LiquidLayer` blurs its whole area every frame; keep it hidden when nothing is in it, and never stack two full-screen layers that are both visible.
- **Reduced motion is also the cheap path**: `motion.reduced` stops idle bubbles and splashes. A heavier lite mode (no blur) joins `Motion.pace` as the single precedence function when it is built (V/AS `animation/08-degradation.md`).
