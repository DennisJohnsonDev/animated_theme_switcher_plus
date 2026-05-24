import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'clippers/theme_switcher_box_plus_clipper.dart';
import 'clippers/theme_switcher_circle_plus_clipper.dart';
import 'clippers/theme_switcher_clipper.dart';
import 'clippers/theme_switcher_clipper_bridge.dart';
import 'theme_provider.dart';
import 'theme_switcher.dart';

/// A switching area that renders premium ShaderMask-based reveals for
/// the *Plus* clipper markers ([ThemeSwitcherCirclePlusClipper],
/// [ThemeSwitcherBoxPlusClipper]) and falls back to the legacy
/// [ClipPath] rendering for every other clipper.
///
/// Supports forward and reverse playback. Forward reveals the new theme
/// over the old screenshot; reverse shrinks the old screenshot off the
/// new theme. In both directions, all visible motion is compressed into
/// the first half of the controller timeline — once it's done, the
/// controller is snapped to its endpoint so the tap gate opens
/// immediately instead of dragging through imperceptible motion.
class PremiumThemeSwitchingArea extends StatelessWidget {
  const PremiumThemeSwitchingArea({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  /// Default controller duration used during a premium reveal.
  static const Duration premiumDuration = Duration(milliseconds: 2000);

  /// Trigger a premium theme reveal anchored at [offset]. Manages the
  /// controller duration override and restoration so callers don't have
  /// to. Silently no-ops if an animation is already running.
  static void changeTheme(
    BuildContext context, {
    required ThemeData theme,
    Offset? offset,
    bool isReversed = false,
    Duration duration = premiumDuration,
  }) {
    final model = ThemeModelInheritedNotifier.of(context);
    if (model.controller.isAnimating) return;
    final original = model.controller.duration;
    model.controller.duration = duration;
    ThemeSwitcher.of(context).changeTheme(
      theme: theme,
      isReversed: isReversed,
      offset: offset,
      onAnimationFinish: () {
        if (original != null) model.controller.duration = original;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = ThemeModelInheritedNotifier.of(context);
    Widget content;

    if (model.oldTheme == null || model.oldTheme == model.theme) {
      content = _page(model.theme);
    } else if (_isPremium(model.clipper)) {
      content = _premiumReveal(model);
    } else {
      content = _legacyReveal(model);
    }

    return Material(child: content);
  }

  static bool _isPremium(ThemeSwitcherClipper c) =>
      c is ThemeSwitcherCirclePlusClipper ||
      c is ThemeSwitcherBoxPlusClipper;

  Widget _page(ThemeData theme) => Theme(
        key: const ValueKey('PremiumThemeSwitchingArea_page'),
        data: theme,
        child: child,
      );

  Widget _premiumReveal(ThemeModel model) {
    final isReversed = model.isReversed;
    final isBox = model.clipper is ThemeSwitcherBoxPlusClipper;

    // Layer roles by direction:
    //   Forward: bottom = old screenshot (fades & zooms), top = new theme
    //            (masked, scales in from 1.04 → 1.0).
    //   Reverse: bottom = new theme (always visible), top = old screenshot
    //            (mask shrinks from full → 0 to reveal new beneath).
    final bottomLayer = isReversed
        ? _page(model.theme)
        : RawImage(image: model.image);
    final topLayer = isReversed
        ? RawImage(image: model.image)
        : _page(model.theme);

    return AnimatedBuilder(
      animation: model.controller,
      builder: (_, __) {
        final t = model.controller.value;

        // Normalized progress: 0 at start of the visible animation, 1 at
        // its end — regardless of playback direction.
        final progress = isReversed ? (1.0 - t) : t;

        // Compress all visible motion into the first half of the
        // controller timeline; the rest is dead time we snap off.
        const visibleEnd = 0.5;
        final compressed = (progress / visibleEnd).clamp(0.0, 1.0);
        final eased = Curves.easeOutSine.transform(compressed);

        // Incoming/top scale lands slightly before the mask completes
        // so the page is locked at scale 1.0 while the mask finishes.
        const scaleFinish = 0.62;
        final scaleEased = compressed < scaleFinish
            ? Curves.easeOutSine.transform(compressed / scaleFinish)
            : 1.0;

        // Snap to the controller endpoint once visible motion is done.
        // Forward end = 1.0, reverse end = 0.0.
        final shouldSnap =
            isReversed ? (t <= visibleEnd) : (t >= visibleEnd);
        if (shouldSnap && model.controller.isAnimating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (model.controller.isAnimating) {
              // Order matters: stop(canceled: false) completes the
              // TickerFuture so .then() → onAnimationFinish → duration
              // reset runs. The value setter would otherwise call
              // stop(canceled: true) internally and reject the future.
              model.controller.stop(canceled: false);
              model.controller.value = isReversed ? 0.0 : 1.0;
            }
          });
        }

        // Mask "fill" factor: forward grows 0→1; reverse shrinks 1→0.
        final maskFactor = isReversed ? (1.0 - eased) : eased;

        final maskedTop = isBox
            ? _FeatheredBoxMask(
                tap: model.switcherOffset,
                factor: maskFactor,
                child: topLayer,
              )
            : _FeatheredCircleMask(
                tap: model.switcherOffset,
                factor: maskFactor,
                child: topLayer,
              );

        if (isReversed) {
          // Reverse: new theme stays static beneath, old screenshot on
          // top shrinks away via the feathered mask. Premium feel here
          // comes from the soft edge — no fade/scale overlay needed.
          return Stack(
            fit: StackFit.expand,
            children: [
              bottomLayer,
              if (model.isAnimating) maskedTop,
            ],
          );
        }

        // Forward: outgoing fades + zooms slightly (recedes) under the
        // incoming, which arrives masked and scales 1.04 → 1.0
        // (depth bloom).
        return Stack(
          fit: StackFit.expand,
          children: [
            if (model.isAnimating)
              Opacity(
                opacity:
                    math.pow(1 - eased, 0.6).toDouble().clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1.0 + 0.04 * eased,
                  child: bottomLayer,
                ),
              ),
            Transform.scale(
              scale: 1.04 - 0.04 * scaleEased,
              child: maskedTop,
            ),
          ],
        );
      },
    );
  }

  Widget _legacyReveal(ThemeModel model) {
    final outgoing = model.isReversed
        ? _page(model.theme)
        : RawImage(image: model.image);
    final incoming = model.isReversed
        ? RawImage(image: model.image)
        : _page(model.theme);

    return Stack(
      children: [
        if (model.isAnimating)
          Container(
            key: const ValueKey('PremiumThemeSwitchingArea_legacy_first'),
            child: outgoing,
          ),
        AnimatedBuilder(
          key: const ValueKey('PremiumThemeSwitchingArea_legacy_second'),
          animation: model.controller,
          child: incoming,
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
}

/// Feathered circular reveal via a single radial-gradient ShaderMask.
class _FeatheredCircleMask extends StatelessWidget {
  const _FeatheredCircleMask({
    required this.tap,
    required this.factor,
    required this.child,
  });

  final Offset tap;
  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final w = math.max(tap.dx, rect.width - tap.dx);
        final h = math.max(tap.dy, rect.height - tap.dy);
        final maxR = math.sqrt(w * w + h * h);
        final r = maxR * factor;
        final align = Alignment(
          (tap.dx / rect.width) * 2 - 1,
          (tap.dy / rect.height) * 2 - 1,
        );
        return RadialGradient(
          center: align,
          radius: r / (rect.shortestSide / 2 + 0.0001),
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: const [0.0, 0.85, 1.0],
        ).createShader(rect);
      },
      child: child,
    );
  }
}

/// Feathered rectangular reveal — produced by composing two
/// LinearGradient ShaderMasks (one horizontal, one vertical). Their
/// alphas multiply to form a soft-edged rectangle that grows from [tap].
class _FeatheredBoxMask extends StatelessWidget {
  const _FeatheredBoxMask({
    required this.tap,
    required this.factor,
    required this.child,
  });

  static const double _feather = 60.0;

  final Offset tap;
  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => _axisFeatherShader(
        rect: rect,
        center: tap.dx,
        extent: rect.width,
        maxHalf: math.max(tap.dx, rect.width - tap.dx),
        factor: factor,
        feather: _feather,
        horizontal: true,
      ),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => _axisFeatherShader(
          rect: rect,
          center: tap.dy,
          extent: rect.height,
          maxHalf: math.max(tap.dy, rect.height - tap.dy),
          factor: factor,
          feather: _feather,
          horizontal: false,
        ),
        child: child,
      ),
    );
  }
}

/// Builds a LinearGradient shader along one axis: transparent → opaque →
/// opaque → transparent with the opaque band centered on [center],
/// half-width = `maxHalf · factor`, and a [feather] transition on each side.
Shader _axisFeatherShader({
  required Rect rect,
  required double center,
  required double extent,
  required double maxHalf,
  required double factor,
  required double feather,
  required bool horizontal,
}) {
  final half = maxHalf * factor;
  final c = (center / extent).clamp(0.0, 1.0);
  final h = half / extent;
  final f = feather / extent;

  double s0 = (c - h - f).clamp(0.0, 1.0);
  double s1 = (c - h).clamp(0.0, 1.0);
  double s2 = (c + h).clamp(0.0, 1.0);
  double s3 = (c + h + f).clamp(0.0, 1.0);

  // Stops must be non-decreasing; clamping individually can violate that
  // when the band overshoots an edge, so enforce monotonicity.
  if (s1 < s0) s1 = s0;
  if (s2 < s1) s2 = s1;
  if (s3 < s2) s3 = s2;

  return LinearGradient(
    begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
    end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
    colors: const [
      Color(0x00FFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [s0, s1, s2, s3],
  ).createShader(rect);
}
