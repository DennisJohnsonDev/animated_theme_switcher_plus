import 'dart:async';
import 'dart:ui' as ui;

import 'package:animated_theme_switcher_plus/animated_theme_switcher_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Builds a widget for the current [ThemeData] held by a [ThemeProvider].
typedef ThemeBuilder = Widget Function(BuildContext, ThemeData theme);

/// The root of the theme-switching machinery.
///
/// Place this above your `MaterialApp`. It owns the [AnimationController] that
/// drives every reveal, exposes the shared [ThemeModel] to descendants through
/// [ThemeModelInheritedNotifier], and wraps its subtree in a `RepaintBoundary`
/// so the outgoing theme can be captured as a bitmap before each switch.
///
/// Provide exactly one of [builder] or [child].
///
/// ```dart
/// ThemeProvider(
///   initTheme: lightTheme,
///   builder: (_, theme) => MaterialApp(theme: theme, home: const HomePage()),
/// );
/// ```
class ThemeProvider extends StatefulWidget {
  /// Creates a theme provider holding [initTheme] as the starting theme.
  const ThemeProvider({
    super.key,
    this.builder,
    this.child,
    required this.initTheme,
    this.duration = const Duration(milliseconds: 300),
  });

  /// Rebuilt with the active theme whenever the theme changes.
  ///
  /// Use this when the subtree needs the theme — typically to feed a
  /// `MaterialApp`'s `theme` argument. Ignored when [child] is non-null.
  final ThemeBuilder? builder;

  /// A subtree that does not itself need the active theme.
  ///
  /// Takes precedence over [builder] when both are supplied.
  final Widget? child;

  /// The theme the app starts with.
  final ThemeData initTheme;

  /// How long a reveal takes.
  ///
  /// [PremiumThemeSwitchingArea.changeTheme] temporarily overrides this for the
  /// duration of a premium reveal and restores it when the reveal finishes.
  final Duration duration;

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<ThemeProvider>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late ThemeModel model;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    model = ThemeModel(
      startTheme: widget.initTheme,
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModelInheritedNotifier(
      notifier: model,
      child: Builder(builder: (context) {
        var model = ThemeModelInheritedNotifier.of(context);
        return RepaintBoundary(
          key: model.previewContainer,
          child: widget.child ?? widget.builder!(context, model.theme),
        );
      }),
    );
  }
}

/// Exposes the active [ThemeModel] to the widgets below a [ThemeProvider].
///
/// Descendants that depend on this notifier rebuild whenever the model changes
/// — on a theme switch, and on each frame of a reveal.
class ThemeModelInheritedNotifier extends InheritedNotifier<ThemeModel> {
  /// Creates a notifier exposing [notifier] to [child].
  const ThemeModelInheritedNotifier({
    super.key,
    required ThemeModel notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// The nearest enclosing [ThemeModel].
  ///
  /// Reading `ThemeModelInheritedNotifier.of(context).theme` is the usual way
  /// to branch on the currently active theme:
  ///
  /// ```dart
  /// final isDark = ThemeModelInheritedNotifier.of(context).theme.brightness
  ///     == Brightness.dark;
  /// ```
  ///
  /// Throws if there is no [ThemeProvider] above `context`.
  static ThemeModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeModelInheritedNotifier>()!
        .notifier!;
  }
}

/// The shared state behind a theme switch.
///
/// Holds the active and outgoing themes, the captured screenshot of the
/// outgoing theme, the reveal origin, and the [AnimationController] the
/// switching areas animate against. Obtain it with
/// [ThemeModelInheritedNotifier.of].
class ThemeModel extends ChangeNotifier {
  ThemeData _theme;

  /// Key of the [ThemeSwitcher] that started the current switch.
  late GlobalKey switcherGlobalKey;

  /// Screenshot of the app rendered in [oldTheme].
  ///
  /// Used as the outgoing layer during a reveal. Null before the first switch.
  ui.Image? image;

  /// Key of the `RepaintBoundary` that [image] is captured from.
  final previewContainer = GlobalKey();

  /// Reserved for scheduling work during a switch.
  Timer? timer;

  /// The clipper that decides the shape of the current reveal.
  ThemeSwitcherClipper clipper = const ThemeSwitcherCircleClipper();

  /// Drives every reveal; its value runs 0 → 1 forward and 1 → 0 reversed.
  final AnimationController controller;

  /// Creates a model starting at [startTheme] and driven by [controller].
  ThemeModel({
    required ThemeData startTheme,
    required this.controller,
  }) : _theme = startTheme;

  /// The theme currently in effect.
  ThemeData get theme => _theme;

  /// The theme being animated away from, or null before the first switch.
  ThemeData? oldTheme;

  /// Whether the current reveal plays backwards.
  bool isReversed = false;

  /// Whether a reveal is on screen right now.
  bool isAnimating = false;

  /// Global coordinates the current reveal expands from.
  late Offset switcherOffset;

  /// Switches to [theme], revealing it from the widget identified by [key].
  ///
  /// Prefer calling [ThemeSwitcherState.changeTheme] or
  /// [PremiumThemeSwitchingArea.changeTheme] — both delegate here with the
  /// right key and clipper already filled in.
  ///
  /// Returns immediately, doing nothing, if a reveal is already running:
  /// concurrent switches are dropped rather than queued. [onAnimationFinish]
  /// fires once the reveal completes.
  void changeTheme({
    required ThemeData theme,
    required GlobalKey key,
    ThemeSwitcherClipper? clipper,
    required bool isReversed,
    Offset? offset,
    VoidCallback? onAnimationFinish,
  }) async {
    if (controller.isAnimating) {
      return;
    }

    if (clipper != null) {
      this.clipper = clipper;
    }
    this.isReversed = isReversed;

    oldTheme = _theme;
    _theme = theme;
    switcherOffset = _getSwitcherCoordinates(key, offset);
    await _saveScreenshot();

    isAnimating = true;

    if (isReversed) {
      await controller.reverse(from: 1.0).then(
        (value) {
          isAnimating = false;
          onAnimationFinish?.call();
        },
      );
    } else {
      await controller.forward(from: 0.0).then(
        (value) {
          isAnimating = false;
          onAnimationFinish?.call();
        },
      );
    }
  }

  Future<void> _saveScreenshot() async {
    final context = previewContainer.currentContext!;
    final boundary = context.findRenderObject() as RenderRepaintBoundary;
    image = await boundary.toImage(
      pixelRatio: View.of(context).devicePixelRatio,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Offset _getSwitcherCoordinates(
      GlobalKey<State<StatefulWidget>> switcherGlobalKey,
      [Offset? tapOffset]) {
    final renderObject =
        switcherGlobalKey.currentContext!.findRenderObject()! as RenderBox;
    final size = renderObject.size;
    return renderObject.localToGlobal(Offset.zero).translate(
          tapOffset?.dx ?? (size.width / 2),
          tapOffset?.dy ?? (size.height / 2),
        );
  }
}
