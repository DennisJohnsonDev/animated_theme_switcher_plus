import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'theme_switcher_clipper.dart';

/// Marker clipper for [PremiumThemeSwitchingArea] — when this is the active
/// clipper, the area renders the premium ShaderMask reveal instead of
/// path-based clipping. [getClip] is never called on the premium path;
/// a plain circle is provided as a fallback if used with [ThemeSwitchingArea].
class ThemeSwitcherCirclePlusClipper implements ThemeSwitcherClipper {
  const ThemeSwitcherCirclePlusClipper();

  @override
  Path getClip(Size size, Offset? offset, double? sizeRate) {
    final origin = offset ?? Offset(size.width / 2, size.height / 2);
    final t = (sizeRate ?? 0.0).clamp(0.0, 1.0);
    final w = math.max(origin.dx, size.width - origin.dx);
    final h = math.max(origin.dy, size.height - origin.dy);
    return Path()
      ..addOval(Rect.fromCircle(
        center: origin,
        radius: t * math.sqrt(w * w + h * h),
      ));
  }

  @override
  bool shouldReclip(
          CustomClipper<Path> oldClipper, Offset? offset, double? sizeRate) =>
      true;
}
