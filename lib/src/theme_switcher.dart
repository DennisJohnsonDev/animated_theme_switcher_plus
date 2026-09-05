import 'package:flutter/material.dart';

import 'clippers/theme_switcher_circle_clipper.dart';
import 'clippers/theme_switcher_clipper.dart';
import 'theme_provider.dart';

/// Signature for a callback that switches to [theme].
typedef ChangeTheme = void Function(ThemeData theme);

/// Builder that receives the enclosing [ThemeSwitcherState].
///
/// Used by [ThemeSwitcher.switcher].
typedef BuilderWithSwitcher = Widget Function(
    BuildContext, ThemeSwitcherState switcher);

/// Builder that receives the enclosing [ThemeSwitcherState] and active theme.
///
/// Used by [ThemeSwitcher.withTheme].
typedef BuilderWithTheme = Widget Function(
    BuildContext, ThemeSwitcherState switcher, ThemeData theme);

/// Wraps the widget that triggers a theme switch.
///
/// The reveal animation expands from this widget, so wrap the actual control
/// the user touches — a button, a switch, a list tile — rather than a whole
/// screen. Call [ThemeSwitcher.of] from inside [builder] to start a switch.
///
/// ```dart
/// ThemeSwitcher(
///   clipper: const ThemeSwitcherCircleClipper(),
///   builder: (context) => IconButton(
///     icon: const Icon(Icons.brightness_6),
///     onPressed: () => ThemeSwitcher.of(context).changeTheme(theme: darkTheme),
///   ),
/// );
/// ```
///
/// See also [ThemeSwitcher.switcher] and [ThemeSwitcher.withTheme], which pass
/// the switcher — and the active theme — straight into the builder.
class ThemeSwitcher extends StatefulWidget {
  /// Creates a switcher whose reveal uses [clipper].
  const ThemeSwitcher({
    super.key,
    this.clipper = const ThemeSwitcherCircleClipper(),
    required this.builder,
  });

  /// A [ThemeSwitcher] whose builder is handed the switcher directly.
  ///
  /// Saves a `ThemeSwitcher.of(context)` lookup inside the builder.
  ///
  /// ```dart
  /// ThemeSwitcher.switcher(
  ///   builder: (context, switcher) => IconButton(
  ///     icon: const Icon(Icons.palette),
  ///     onPressed: () => switcher.changeTheme(theme: pinkTheme),
  ///   ),
  /// );
  /// ```
  factory ThemeSwitcher.switcher({
    Key? key,
    clipper = const ThemeSwitcherCircleClipper(),
    required BuilderWithSwitcher builder,
  }) =>
      ThemeSwitcher(
        key: key,
        clipper: clipper,
        builder: (ctx) => builder(ctx, ThemeSwitcher.of(ctx)),
      );

  /// A [ThemeSwitcher] whose builder is handed the switcher and active theme.
  ///
  /// Convenient for toggles that branch on the current brightness.
  ///
  /// ```dart
  /// ThemeSwitcher.withTheme(
  ///   builder: (context, switcher, theme) => IconButton(
  ///     icon: const Icon(Icons.brightness_6),
  ///     onPressed: () => switcher.changeTheme(
  ///       theme: theme.brightness == Brightness.light ? darkTheme : lightTheme,
  ///     ),
  ///   ),
  /// );
  /// ```
  factory ThemeSwitcher.withTheme({
    Key? key,
    clipper = const ThemeSwitcherCircleClipper(),
    required BuilderWithTheme builder,
  }) =>
      ThemeSwitcher.switcher(
        key: key,
        clipper: clipper,
        builder: (ctx, s) =>
            builder(ctx, s, ThemeModelInheritedNotifier.of(ctx).theme),
      );

  /// Builds the widget the user interacts with.
  final Widget Function(BuildContext) builder;

  /// Shape of the reveal started from this switcher.
  ///
  /// Defaults to [ThemeSwitcherCircleClipper]. Pass
  /// [ThemeSwitcherCirclePlusClipper] or [ThemeSwitcherBoxPlusClipper] to get
  /// the feathered reveals under a [PremiumThemeSwitchingArea].
  final ThemeSwitcherClipper clipper;

  @override
  ThemeSwitcherState createState() => ThemeSwitcherState();

  /// The state of the nearest enclosing [ThemeSwitcher].
  ///
  /// Throws if `context` is not inside a [ThemeSwitcher].
  static ThemeSwitcherState of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_InheritedThemeSwitcher>()!;
    return inherited.data;
  }
}

/// State of a [ThemeSwitcher]; call [changeTheme] to start a switch.
class ThemeSwitcherState extends State<ThemeSwitcher> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return _InheritedThemeSwitcher(
      data: this,
      child: Builder(
        key: _globalKey,
        builder: widget.builder,
      ),
    );
  }

  /// Switches the app to [theme], revealing it from this switcher.
  ///
  /// [offset] is local to this switcher — pass `details.localPosition` from a
  /// `TapDownDetails` to anchor the reveal at the exact touch point. Omit it
  /// and the reveal starts from the switcher's centre.
  ///
  /// Set [isReversed] to peel the outgoing theme away instead of growing the
  /// incoming one over it. [onAnimationFinish] fires when the reveal completes.
  ///
  /// Does nothing if a reveal is already running.
  void changeTheme({
    required ThemeData theme,
    bool isReversed = false,
    Offset? offset,
    VoidCallback? onAnimationFinish,
  }) {
    ThemeModelInheritedNotifier.of(context).changeTheme(
        theme: theme,
        key: _globalKey,
        clipper: widget.clipper,
        isReversed: isReversed,
        offset: offset,
        onAnimationFinish: onAnimationFinish);
  }
}

class _InheritedThemeSwitcher extends InheritedWidget {
  final ThemeSwitcherState data;

  const _InheritedThemeSwitcher({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedThemeSwitcher oldWidget) {
    return true;
  }
}
