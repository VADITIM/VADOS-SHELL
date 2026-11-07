# VADOS-SHELL: Architecture & Development Direction

## Product vision

VADOS-SHELL is a declarative, interactive Wayland desktop shell built
around a unified liquid interaction system. Its identity comes from
spatially coherent motion: panels and surfaces should feel like
connected manifestations of one environment, not independent windows
with unrelated animations.

The goal is a polished daily-driver experience with real usability,
reliable behavior, and a distinctive visual language. DriftWM is the
primary development target, while the core shell should remain usable
across supported Arch Linux compositors.

## Core architectural principle

**One coherent interaction engine, implemented as independently testable
subsystems.**

A unified visual language does not require a monolithic implementation.
Keep the engine modular, deterministic, and independent of individual
features and compositor-specific behavior.

## Proposed architecture

``` text
VADOS EXPERIENCE LAYER
  Taskbar · Search · Dashboard · Settings · Notifications
                    |
                    v
LIQUID INTERACTION ENGINE
  Transition orchestration · Morphing · Gestures · Interruption handling
                    |
          +---------+---------+
          |         |         |
          v         v         v
      Motion    Geometry   State machine
      system     system      system
          \         |         /
           \        |        /
            v       v       v
             Rendering system
                    |
                    v
PLATFORM ADAPTERS
  Quickshell · Wayland · DriftWM · Hyprland · Other compositors
                    |
                    v
             System services
```

### 1. Experience layer

Feature modules own user-facing functionality and compose shared
primitives.

-   Taskbar
-   Search / launcher
-   Dashboard
-   Settings
-   Notifications
-   System controls
-   Other desktop surfaces

Modules should communicate through explicit shared state and service
interfaces, not by importing one another. Keep feature-specific behavior
inside its module.

### 2. Liquid interaction engine

The engine coordinates transitions between surfaces and owns the shared
interaction language.

Its responsibilities include:

-   Surface-to-surface transitions and morphing.
-   Transition orchestration and sequencing.
-   Gesture interpretation and velocity.
-   Animation interruption, reversal, and cancellation.
-   Consistent transition lifecycle handling.
-   Shared motion and geometry contracts.

The engine must not contain application-specific behavior or
compositor-specific assumptions.

### 3. Motion system

Centralize motion behavior rather than duplicating animation constants
across components.

Define reusable profiles for:

-   Duration and easing.
-   Spring stiffness and damping.
-   Acceleration and velocity.
-   Overshoot and settling.
-   Gesture-driven motion.
-   Reduced-motion behavior.

Different interaction types may use different profiles, but they should
follow a consistent system-wide language.

### 4. Geometry system

Own the spatial relationships between surfaces.

Responsibilities:

-   Anchors and origin points.
-   Source and destination bounds.
-   Morph paths and shape interpolation.
-   Shared geometry measurements.
-   Screen and monitor coordinate handling.
-   Geometry changes during active transitions.

Geometry calculations should be reusable and independent of the feature
requesting them.

### 5. State machine

Represent transitions as explicit, deterministic states rather than
loosely coordinated Boolean properties.

Suggested lifecycle:

``` text
Idle
  -> Preparing
  -> Entering
  -> Active
  -> Exiting
  -> Idle

Any active transition
  -> Interrupted
  -> Recovering
  -> Valid state
```

The state machine must support:

-   Interruption at any point.
-   Reversal without visual or logical corruption.
-   Cancellation and recovery.
-   Rapid consecutive input.
-   Consistent source and destination state.
-   No orphaned surfaces or stuck interaction states.

### 6. Rendering system

Own shared rendering behavior such as clipping, compositing, masks,
blur, and visual effects.

Keep rendering concerns separate from application state and transition
decisions. Establish performance budgets and profile expensive effects
on real hardware.

## State, services, and module boundaries

Preserve clear ownership:

-   **Config:** User configuration, appearance, motion profiles, and
    feature settings.
-   **State:** Shared UI state and explicit cross-module communication.
-   **Services:** Data and system integrations without UI ownership.
-   **Components:** Reusable visual and interaction primitives.
-   **Modules:** Independent user-facing features.
-   **Windows:** Layer-shell hosts and per-screen surface ownership.
-   **Keybinds / IPC:** Input entry points that request state changes
    rather than implementing feature logic.
-   **Compositor adapters:** The only layer that translates
    compositor-specific protocols and behavior.

Rules:

1.  Modules must not import other feature modules.
2.  Shared communication goes through state or service interfaces.
3.  Services contain no UI.
4.  Components remain reusable and feature-agnostic.
5.  Compositor-specific code stays behind adapters.
6.  Configuration is explicit, validated, and has sensible defaults.
7.  Every major subsystem should be independently testable.

## Compositor portability

Use capability discovery instead of assuming every compositor provides
identical functionality.

Example capability contract:

``` qml
Compositor.capabilities = {
    windowGeometry: true,
    windowMinimize: true,
    windowSnap: true,
    workspaceManagement: true,
    freeCanvas: true,
    layerShell: true
}
```

This is an illustrative contract; the implementation should reflect the
actual APIs and protocols available.

Separate functionality into three levels:

  -----------------------------------------------------------------------
  Level                               Scope
  ----------------------------------- -----------------------------------
  Core                                Shell surfaces, taskbar, search,
                                      settings, shared animation

  Extended                            Window information, workspace
                                      integration, focus and geometry

  Native                              DriftWM-specific desktop modes and
                                      advanced window management
  -----------------------------------------------------------------------

Core functionality should remain usable without DriftWM. Extended and
native features should detect capabilities and degrade gracefully.
DriftWM should be the first-class development target, not a dependency
of the liquid engine.

## UX and interaction principles

1.  **Motion communicates relationships.** A surface should visually
    emerge from the control or location that invoked it and return
    coherently.
2.  **Interaction minimizes cognitive effort.** Visual effects must not
    make common tasks slower or harder.
3.  **Visual complexity must not create operational complexity.** The
    interface should remain predictable and discoverable.
4.  **Keyboard and pointer interaction are first-class.** Search,
    navigation, and common actions should be fast without relying on
    animation.
5.  **Every transition is interruptible.** Users must remain in control
    during motion.
6.  **Reduced motion is supported.** Essential functionality must not
    depend on animation.
7.  **Daily-driver reliability comes first.** The shell must remain
    usable during long sessions, under load, and across monitor
    configurations.

## Performance and reliability requirements

-   Target stable 60 FPS, with support for high-refresh-rate displays
    where hardware permits.
-   Profile animations and rendering under GPU load.
-   Test multi-monitor layouts, scaling, resolution changes, and screen
    hotplugging.
-   Avoid unnecessary reactive bindings and repeated expensive
    calculations.
-   Prevent overlapping transitions from producing invalid states.
-   Ensure surfaces recover cleanly after interrupted animations or
    service failures.
-   Provide useful logs and actionable error reporting.

## Development roadmap

### Phase 1: Engine integrity

-   Define subsystem interfaces and ownership.
-   Implement reusable geometry primitives.
-   Centralize motion profiles.
-   Implement the transition state machine.
-   Support interruption, reversal, cancellation, and recovery.
-   Establish rendering and performance budgets.
-   Implement reduced-motion behavior.

**Exit condition:** Transitions can be created, interrupted, reversed,
and chained without inconsistent visual or logical states.

### Phase 2: Complete vertical slice

Build one complete, polished interaction:

-   Taskbar.
-   Search.
-   Taskbar-to-search morph.
-   Search-to-taskbar return.
-   Keyboard and pointer interaction.
-   Rapid input and interruption handling.
-   Error and recovery behavior.

**Exit condition:** Search works as a finished daily-use feature, not
merely as an animation demonstration.

### Phase 3: Daily-driver functionality

Add and polish:

-   Settings.
-   Notifications.
-   Audio and brightness controls.
-   Network and battery.
-   Clipboard.
-   System tray.
-   Multi-monitor behavior.

**Exit condition:** Normal daily computing can be performed without
routinely falling back to external shell utilities.

### Phase 4: Compositor support

-   Complete the DriftWM adapter.
-   Implement additional compositor adapters.
-   Add capability discovery and graceful degradation.
-   Test supported compositors and document feature differences.

**Exit condition:** Core functionality works without DriftWM, with
compositor-specific features clearly identified.

### Phase 5: Productization

-   Installation and upgrade process.
-   Configuration validation and migration.
-   Logging and diagnostics.
-   Documentation and troubleshooting.
-   Release and compatibility policy.
-   Real-world user testing.

**Exit condition:** A user unfamiliar with the development environment
can install, configure, update, and use VADOS-SHELL reliably.

## Definition of progress

Measure progress by the reliability and leverage of the foundations, not
by the number of features or animations implemented.

A successful subsystem makes future features:

-   Easier to implement.
-   Easier to test.
-   Easier to maintain.
-   More consistent with the rest of the shell.
-   Less dependent on unrelated modules or compositor details.

Prioritize engine integrity and one complete vertical slice before
expanding the feature set.

## Product differentiation

VADOS-SHELL should be defined by a desktop interaction model in which
surfaces behave as parts of one continuous, spatially coherent system.

The differentiator is not simply more animation, blur, widgets, or
customization. It is the combination of:

-   Consistent spatial relationships.
-   Meaningful motion.
-   Responsive interaction.
-   Strong keyboard and pointer UX.
-   Reliable daily-driver behavior.
-   A modular engine that supports the experience without becoming a
    monolith.
