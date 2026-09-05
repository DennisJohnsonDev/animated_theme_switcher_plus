import 'package:flutter/material.dart';
import 'theme_switcher_clipper.dart';

/// Reveals the incoming theme through a hard-edged rectangle.
///
/// The rectangle grows outward from the reveal origin until it covers the
/// switching area.
///
/// For a soft-edged version of the same motion, use
/// [ThemeSwitcherBoxPlusClipper] under a [PremiumThemeSwitchingArea].
class ThemeSwitcherBoxClipper implements ThemeSwitcherClipper {
  /// Creates a rectangular reveal.
  const ThemeSwitcherBoxClipper();

  @override
  Path getClip(Size size, Offset offset, double sizeRate) {
    return Path()
      ..addRect(
        Rect.fromCenter(
          center: offset,
          width: size.width * 2 * sizeRate,
          height: size.height * 2 * sizeRate,
        ),
      );
  }

  @override
  bool shouldReclip(
      CustomClipper<Path> oldClipper, Offset? offset, double? sizeRate) {
    return true;
  }
}
