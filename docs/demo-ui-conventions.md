# Demo UI Overlay Convention

All scenes under `res://demo/` participate in the shared collapsible demo-overlay behavior provided by `DemoOverlayController`.

The purpose of this convention is to let human QA switch between two equally important validation modes:

- an instrumented view with diagnostics and controls visible; and
- an unobstructed view for watching geometry, streaming, animation, and other visual behavior directly.

## Required behavior

Every demo must preserve a persistent, accessible `Hide UI` / `Show UI` control.

When the UI is collapsed:

- every `CanvasLayer` owned by the active demo scene is hidden;
- mobile touch-control overlays are hidden with the rest of the demo UI;
- each overlay layer's previous visibility state is preserved rather than flattened;
- the restore control remains visible and usable; and
- on Web builds, the injected GitHub Pages demo selector is hidden as well.

When the UI is restored, each demo overlay returns to the visibility state it had before collapse.

## Ownership

`DemoOverlayController` is validation infrastructure. Production terrain, field, meshing, baking, and streaming systems must not depend on it.

The controller is installed as an autoload and only activates when the current scene path begins with `res://demo/`. This makes collapsibility the default for current and future demos without requiring feature-specific wiring.

Do not implement separate collapse logic in individual demo scripts unless the shared controller cannot represent a genuinely different validation requirement.

## Accessibility

The persistent restore control must remain large enough for touch interaction and readable without requiring the rest of the overlay to be visible.

Do not solve layout pressure by shrinking the restore control below the project's established accessible touch-target and typography expectations.

## Validation

Changes to demo overlay behavior must keep `tests/test_demo_overlay_controller.gd` green. That test verifies that:

- future `res://demo/` scenes participate automatically;
- production paths do not activate the convention;
- multiple demo overlay layers collapse together;
- the persistent restore control remains available; and
- restoring the UI restores the affected layers coherently.
