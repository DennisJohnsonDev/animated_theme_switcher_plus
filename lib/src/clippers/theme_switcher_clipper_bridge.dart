import 'package:flutter/material.dart';
import 'theme_switcher_clipper.dart';

/// Adapts a [ThemeSwitcherClipper] to Flutter's [CustomClipper] interface.
///
/// `ClipPath` only accepts a [CustomClipper]; this forwards to the package's
/// own clipper interface, supplying the reveal origin and progress that a
/// [CustomClipper] has no way to carry itself. Written for internal use — when
/// adding a reveal shape, implement [ThemeSwitcherClipper] rather than this.
class ThemeSwitcherClipperBridge extends CustomClipper<Path> {
  /// Wraps [clipper], pinning it to [offset] at progress [sizeRate].
  ThemeSwitcherClipperBridge(
      {required this.sizeRate, required this.offset, required this.clipper});

  /// Reveal progress, 0 (nothing shown) to 1 (fully shown).
  final double sizeRate;

  /// Global coordinates the reveal expands from.
  final Offset offset;

  /// The shape being adapted.
  final ThemeSwitcherClipper clipper;

  @override
  Path getClip(Size size) {
    return clipper.getClip(size, offset, sizeRate);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return clipper.shouldReclip(oldClipper, offset, sizeRate);
  }
}
