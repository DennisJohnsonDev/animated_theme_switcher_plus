## 1.0.0

Initial release. Requires Flutter 3.10 or newer (Dart 3).

### Features

- **Premium reveals** — `PremiumThemeSwitchingArea` renders feathered `ShaderMask` transitions with
  soft gradient edges, a depth-bloom scale on the incoming theme, and a receding fade on the
  outgoing one. Available as a radial reveal (`ThemeSwitcherCirclePlusClipper`) and a rectangular
  reveal (`ThemeSwitcherBoxPlusClipper`).
- **Classic reveals** — `ThemeSwitchingArea` animates a hard-edged `ClipPath` that grows from the
  reveal origin, with circle and box clippers included.
- **Tap-anchored origins** — pass an `offset` from `TapDownDetails` so the reveal starts exactly
  where the user touched, rather than at the widget centre.
- **Forward and reverse playback** — `isReversed` inverts the layer order so the outgoing theme
  peels away instead of the incoming theme growing over it. Supported by both rendering modes.
- **Mixed rendering** — `PremiumThemeSwitchingArea` falls back to classic path clipping for any
  non-Plus clipper, so both styles can coexist on one screen without swapping the area widget.
- **Custom clippers** — implement `ThemeSwitcherClipper` to define arbitrary reveal shapes.
- **Duration management** — `PremiumThemeSwitchingArea.changeTheme` applies the longer premium
  duration for the reveal and restores the provider's original duration on completion.
- No dependencies beyond the Flutter SDK.

### Implementation notes

- `ThemeProvider` disposes both its `AnimationController` and its `ThemeModel`, preventing the
  memory leak and the debug-mode "AnimationController was not disposed" assertion.
- Premium reveals compress all visible motion into the first half of the controller timeline and
  then snap the controller to its endpoint, so the tap gate reopens as soon as the animation is
  perceptually finished instead of waiting out imperceptible tail motion.
- Concurrent theme switches are dropped rather than queued — a tap during an in-flight reveal is a
  no-op.
- The screenshot layer is removed from the widget tree once the animation completes.
