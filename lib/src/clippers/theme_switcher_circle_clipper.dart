import 'dart:math';
import 'dart:ui';
import 'theme_switcher_clipper.dart';
import 'package:flutter/material.dart';

/// Reveals the incoming theme through a hard-edged circle.
///
/// The circle grows from the reveal origin until it covers the furthest corner
/// of the switching area. This is the default clipper for [ThemeSwitcher].
///
/// For a soft-edged version of the same motion, use
/// [ThemeSwitcherCirclePlusClipper] under a [PremiumThemeSwitchingArea].
class ThemeSwitcherCircleClipper implements ThemeSwitcherClipper {
  /// Creates a circular reveal.
  const ThemeSwitcherCircleClipper();

  @override
  Path getClip(Size size, Offset? offset, double? sizeRate) {
    return Path()
      ..addOval(
        Rect.fromCircle(
          center: offset!,
          radius: lerpDouble(0, _calcMaxRadius(size, offset), sizeRate!)!,
        ),
      );
  }

  @override
  bool shouldReclip(
      CustomClipper<Path> oldClipper, Offset? offset, double? sizeRate) {
    return true;
  }

  static double _calcMaxRadius(Size size, Offset center) {
    final w = max(center.dx, size.width - center.dx);
    final h = max(center.dy, size.height - center.dy);
    return sqrt(w * w + h * h);
  }
}
