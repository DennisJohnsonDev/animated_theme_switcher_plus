import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme_switcher_clipper.dart';

/// Marker clipper for [PremiumThemeSwitchingArea] — when active, the area
/// renders a feathered rectangular ShaderMask reveal instead of path-based
/// clipping. [getClip] is a plain-rectangle fallback for the legacy
/// [ThemeSwitchingArea] and is not called on the premium path.
class ThemeSwitcherBoxPlusClipper implements ThemeSwitcherClipper {
  const ThemeSwitcherBoxPlusClipper();

  @override
  Path getClip(Size size, Offset? offset, double? sizeRate) {
    final origin = offset ?? Offset(size.width / 2, size.height / 2);
    final t = (sizeRate ?? 0.0).clamp(0.0, 1.0);
    final halfW = math.max(origin.dx, size.width - origin.dx) * t;
    final halfH = math.max(origin.dy, size.height - origin.dy) * t;
    return Path()
      ..addRect(Rect.fromLTRB(
        origin.dx - halfW,
        origin.dy - halfH,
        origin.dx + halfW,
        origin.dy + halfH,
      ));
  }

  @override
  bool shouldReclip(
          CustomClipper<Path> oldClipper, Offset? offset, double? sizeRate) =>
      true;
}
