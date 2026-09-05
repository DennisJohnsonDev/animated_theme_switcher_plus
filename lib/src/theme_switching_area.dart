import 'package:flutter/material.dart';

import 'clippers/theme_switcher_clipper_bridge.dart';
import 'theme_provider.dart';

/// The stage a theme reveal plays on, using classic path clipping.
///
/// Wrap the screen whose theme should animate. While a switch is in flight this
/// stacks a screenshot of the outgoing theme against the live subtree rebuilt
/// under the incoming one, then animates a `ClipPath` between them — producing
/// a hard-edged shape that grows from the reveal origin.
///
/// For soft, feathered reveals use [PremiumThemeSwitchingArea] instead; it
/// falls back to this same rendering for non-Plus clippers.
///
/// ```dart
/// ThemeSwitchingArea(
///   child: Scaffold(...),
/// );
/// ```
class ThemeSwitchingArea extends StatelessWidget {
  /// Creates a switching area around [child].
  const ThemeSwitchingArea({
    super.key,
    required this.child,
  });

  /// The subtree that renders in the active theme.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final model = ThemeModelInheritedNotifier.of(context);
    // Widget resChild;
    Widget child;
    if (model.oldTheme == null || model.oldTheme == model.theme) {
      child = _getPage(model.theme);
    } else {
      late final Widget firstWidget, animWidget;
      if (model.isReversed) {
        firstWidget = _getPage(model.theme);
        animWidget = RawImage(image: model.image);
      } else {
        firstWidget = RawImage(image: model.image);
        animWidget = _getPage(model.theme);
      }

      child = Stack(
        children: [
          if (model.isAnimating)
            Container(
              key: const ValueKey('ThemeSwitchingAreaFirstChild'),
              child: firstWidget,
            ),
          AnimatedBuilder(
            key: const ValueKey('ThemeSwitchingAreaSecondChild'),
            animation: model.controller,
            child: animWidget,
            builder: (_, child) {
              return ClipPath(
                clipper: ThemeSwitcherClipperBridge(
                  clipper: model.clipper,
                  offset: model.switcherOffset,
                  sizeRate: model.controller.value,
                ),
                child: child,
              );
            },
          ),
        ],
      );
    }

    return Material(child: child);
  }

  Widget _getPage(ThemeData brandTheme) {
    return Theme(
      key: const ValueKey('ThemeSwitchingAreaPage'),
      data: brandTheme,
      child: child,
    );
  }
}
