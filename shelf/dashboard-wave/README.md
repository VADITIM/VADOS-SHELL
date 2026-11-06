# Dashboard wave (shelved)

The dashboard's first enter: it poured out of a clip line beside the taskbar as one wave, with a travelling ripple on its top and bottom edges that kept moving while open (the idle liquid motion). Removed on 2026-11-05 for the gather and push-in enter; kept here for later use. Quickshell never loads this folder.

- `Wave.qml`: the body as one `PathPolyline` rebuilt per frame: concave fillets to the root, travelling sine ripple, front bulge (`crest`) weighted by the cube of the distance from the root.
- `Dashboard.qml`: the dashboard root as it was, showing the wiring (`stage` clip, `clock` from a `FrameAnimation`, `reach`, `swell`, `crest`, `surge`) and the enter and leave timelines. It still references `Bubbles`, now `components/Rising.qml`.

Tokens it used, as they were:

- `Appearance.dashboard`: `rootGap 8`, `corner 130`, `fillet 46`, `swellFrom 0.3`, `crest 72`, `ripple 16`, `idleRipple 3`, `wavelength 280`, `recede 0.6`.
- `Motion.dashboard`: `pour 560`, `pourOvershoot 1.25`, `swell 640`, `crestRise 180`, `crestFall 280`, `crestSettle 360`, `rippleDecay 1200`, `waveSpeed 3.2`, `contentDelay 200`, `leave 300`.
