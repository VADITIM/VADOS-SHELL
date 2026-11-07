# Performance rules

Checked in review and with the preview; the shell must cost nothing while idle.

- **Idle costs nothing.** No `FrameAnimation`, `Timer`, process or poll runs while its surface is hidden: services poll only while a window sets `isActive` (`Hardware`, `Traffic`, `Weather`), abilities stop their frame loops when inactive (`Rising.isActive`, `Burst.isActive`), overlay windows are invisible while not present.
- **Frame budget**: script work per frame stays under 4 ms during the heaviest animation (the search burst), measured in the preview. Geometry that depends on several changing values is traced once per frame through `Qt.callLater`, never as chains of bindings over arrays.
- **Liquid layers exist only while shown.** A `LiquidLayer` blurs its whole area every frame; keep it hidden when nothing is in it, and never stack two full-screen layers that are both visible.
- **Reduced motion is also the cheap path**: `motion.reduced` stops idle bubbles and splashes. A heavier lite mode (no blur) joins `Motion.pace` as the single precedence function when it is built (V/AS `animation/08-degradation.md`).
