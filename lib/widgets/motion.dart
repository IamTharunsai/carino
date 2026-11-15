import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Motion system (blueprint ANIMATION & MOTION sheet).
///
/// Two ambient surfaces live here:
///  - [AuroraBackground]: slow-drifting radial-gradient blobs in the brand
///    colours (crimson / coral / plum) behind glass content — the living
///    background used wherever there is no photographic backdrop.
///  - [KenBurnsImage]: a photographic backdrop with a very subtle, slow
///    scale drift so still imagery feels alive without distracting.
///
/// BOTH respect the OS Reduce Motion setting (MediaQuery.disableAnimations):
/// when it is on, they render a single static frame — no controllers run.

/// Animated aurora backdrop: three soft radial blobs drifting on slow,
/// offset sine paths over the theme base colour. Static when the member
/// (or OS) has reduced motion on.
/// Freezes the looping backgrounds (Aurora, Ken Burns). Set by
/// test/flutter_test_config.dart so widget tests can settle; the app never
/// sets it — users get motion unless their phone's Reduce Motion is on.
bool stillBackgrounds = false;

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = stillBackgrounds || MediaQuery.of(context).disableAnimations;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      if (reduce) {
        _drift.stop();
      } else if (!_drift.isAnimating) {
        _drift.repeat(reverse: true);
      }
    } else if (!reduce && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  Widget _blob({
    required double size,
    required Color color,
    required double dx,
    required double dy,
  }) {
    return Positioned(
      left: dx,
      top: dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.midnight : AppColors.porcelain;
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        // Static frame (t = 0.35) when reduced motion is on.
        final t = _reduceMotion ? 0.35 : _drift.value;
        final swayA = math.sin(t * math.pi * 2) * 26;
        final swayB = math.cos(t * math.pi * 2) * 34;
        final swayC = math.sin(t * math.pi * 2 + 2.1) * 20;
        return ColoredBox(
          color: base,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Crimson — upper left.
              _blob(
                size: size.width * 1.15,
                color: AppColors.emberCrimson
                    .withValues(alpha: isDark ? 0.34 : 0.20),
                dx: -size.width * 0.35 + swayA,
                dy: -size.height * 0.22 + swayB * 0.5,
              ),
              // Coral — lower right.
              _blob(
                size: size.width * 1.05,
                color: AppColors.sparkCoral
                    .withValues(alpha: isDark ? 0.26 : 0.16),
                dx: size.width * 0.38 + swayB,
                dy: size.height * 0.52 + swayA * 0.6,
              ),
              // Plum — centre, the depth layer.
              _blob(
                size: size.width * 0.95,
                color: AppColors.plumCharcoal
                    .withValues(alpha: isDark ? 0.55 : 0.14),
                dx: size.width * 0.12 + swayC,
                dy: size.height * 0.26 - swayC * 0.7,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Photographic backdrop with a very subtle slow Ken Burns scale
/// (1.00 -> 1.07 over 24s, reversing). Static single frame when Reduce
/// Motion is on.
class KenBurnsImage extends StatefulWidget {
  const KenBurnsImage({super.key, required this.asset});

  final String asset;

  @override
  State<KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = stillBackgrounds || MediaQuery.of(context).disableAnimations;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      if (reduce) {
        _drift.stop();
      } else if (!_drift.isAnimating) {
        _drift.repeat(reverse: true);
      }
    } else if (!reduce && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) => Transform.scale(
        scale: _reduceMotion ? 1.03 : 1.0 + 0.07 * _drift.value,
        child: child,
      ),
      child: Image.asset(widget.asset, fit: BoxFit.cover),
    );
  }
}
