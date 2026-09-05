/// Animated theme switching for Flutter.
///
/// Change `ThemeData` anywhere in your app and the new theme sweeps across the
/// screen from the point the user touched, instead of snapping over instantly.
///
/// Three widgets cooperate:
///
/// * [ThemeProvider] sits above your `MaterialApp`, owns the animation, and
///   captures the outgoing theme as a bitmap before each switch.
/// * [ThemeSwitchingArea] or [PremiumThemeSwitchingArea] is the stage the
///   reveal plays on — the former clips a hard-edged path, the latter renders a
///   soft, feathered `ShaderMask`.
/// * [ThemeSwitcher] wraps the control the user touches and anchors the reveal.
///
/// ```dart
/// ThemeProvider(
///   initTheme: lightTheme,
///   builder: (_, theme) => MaterialApp(
///     theme: theme,
///     home: PremiumThemeSwitchingArea(
///       child: ThemeSwitcher(
///         clipper: const ThemeSwitcherCirclePlusClipper(),
///         builder: (context) => IconButton(
///           icon: const Icon(Icons.brightness_6),
///           onPressed: () => PremiumThemeSwitchingArea.changeTheme(
///             context,
///             theme: darkTheme,
///           ),
///         ),
///       ),
///     ),
///   ),
/// );
/// ```
library;

export 'src/theme_provider.dart';
export 'src/theme_switcher.dart';
export 'src/theme_switching_area.dart';
export 'src/premium_theme_switching_area.dart';
export 'src/clippers/theme_switcher_clipper.dart';
export 'src/clippers/theme_switcher_circle_clipper.dart';
export 'src/clippers/theme_switcher_box_clipper.dart';
export 'src/clippers/theme_switcher_circle_plus_clipper.dart';
export 'src/clippers/theme_switcher_box_plus_clipper.dart';
