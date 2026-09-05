import 'package:flutter/material.dart';

/// The shape of a theme reveal.
///
/// Implement this to define your own reveal geometry, then pass the result to
/// [ThemeSwitcher.clipper]. Implement this interface rather than Flutter's
/// [CustomClipper] directly — the package adapts it internally via
/// [ThemeSwitcherClipperBridge], which supplies the reveal origin and progress
/// that a bare [CustomClipper] cannot carry.
///
/// ```dart
/// class DiamondClipper implements ThemeSwitcherClipper {
///   const DiamondClipper();
///
///   @override
///   Path getClip(Size size, Offset offset, double sizeRate) {
///     final r = size.longestSide * 2 * sizeRate;
///     return Path()
///       ..moveTo(offset.dx, offset.dy - r)
///       ..lineTo(offset.dx + r, offset.dy)
///       ..lineTo(offset.dx, offset.dy + r)
///       ..lineTo(offset.dx - r, offset.dy)
///       ..close();
///   }
///
///   @override
///   bool shouldReclip(
///           CustomClipper<Path> oldClipper, Offset offset, double sizeRate) =>
///       true;
/// }
/// ```
abstract class ThemeSwitcherClipper {
  /// The region of the incoming theme visible at progress [sizeRate].
  ///
  /// [size] is the size of the switching area and [offset] the global
  /// coordinates the reveal expands from. [sizeRate] runs 0 → 1, so the path
  /// should be empty at 0 and cover the whole area at 1.
  Path getClip(Size size, Offset offset, double sizeRate);

  /// Whether the clip path must be recomputed.
  ///
  /// Return `true` — the path depends on [sizeRate], which changes every frame.
  bool shouldReclip(
      CustomClipper<Path> oldClipper, Offset offset, double sizeRate);
}
