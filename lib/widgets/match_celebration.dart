import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../data/mock_data.dart';
import '../models/member.dart';
import '../theme/app_colors.dart';

/// S-020 — THE SIGNATURE MOMENT (blueprint ANIMATION & MOTION sheet).
///
/// Two sparks travel from each person's side, meet at centre, and bloom
/// into a glow over the A3 match backdrop; the bloom fires a particle
/// burst (brand-colour sparks + confetti) and the copy/buttons rise in
/// with a flutter_animate entrance. Total < 900ms for the core moment.
/// Sound: soft two-note chime (SoundService.matchChime, called by parent).
/// Reduced Motion: static glow + fade-in, no travel, NO particle burst,
/// no entrance motion — handled by checking MediaQuery.disableAnimations.
class MatchCelebrationOverlay extends StatefulWidget {
  const MatchCelebrationOverlay({
    super.key,
    required this.member,
    required this.onMessage,
    required this.onSuggestPlan,
    required this.onPlayGame,
    required this.onClose,
  });

  final Member member;
  final VoidCallback onMessage;
  final VoidCallback onSuggestPlan;
  final VoidCallback onPlayGame;
  final VoidCallback onClose;

  @override
  State<MatchCelebrationOverlay> createState() => _MatchCelebrationOverlayState();
}

class _MatchCelebrationOverlayState extends State<MatchCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _travel; // 0 -> 1 sparks converge
  late final Animation<double> _bloom; // glow scale after they meet
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    // Deterministic burst (fixed seed): same celebratory shape every
    // time, no per-build randomness.
    final rng = math.Random(7);
    const palette = [
      AppColors.sparkCoral,
      AppColors.emberCrimson,
      AppColors.warmIvory,
      AppColors.softRose,
    ];
    _particles = List.generate(26, (i) {
      return _Particle(
        angle: rng.nextDouble() * math.pi * 2,
        distance: 42 + rng.nextDouble() * 58,
        size: 3 + rng.nextDouble() * 4.5,
        color: palette[i % palette.length],
        delay: rng.nextDouble() * 0.3,
        spin: rng.nextDouble() * math.pi,
        confetti: i % 3 == 0,
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 880),
    );
    _travel = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _bloom = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _spark(double alignX, Color color) {
    return Align(
      alignment: Alignment(alignX, 0),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 24, spreadRadius: 6),
          ],
        ),
      ),
    );
  }

  /// S-020: the two AVATARS travel with the sparks — yours from the left,
  /// theirs from the right — so the moment is about two real people.
  Widget _avatar(double alignX, String asset) {
    return Align(
      alignment: Alignment(alignX * 0.55, 0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.warmIvory, width: 2),
        ),
        child: CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage(asset),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppConfig.assetBackdropMatch, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0x73151014)),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.warmIvory),
                    onPressed: widget.onClose,
                    tooltip: 'Close',
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = reduceMotion ? 1.0 : _travel.value;
                      final bloom = reduceMotion ? 1.0 : _bloom.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Bloom glow behind the joined sparks.
                          Transform.scale(
                            scale: 0.6 + 0.7 * bloom,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.sparkCoral.withValues(alpha: 0.55 * bloom),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _avatar(-1 + t, MockData.currentUser.photoAsset),
                          _avatar(1 - t, widget.member.photoAsset),
                          _spark(-1 + t, AppColors.sparkCoral), // mine, from left
                          _spark(1 - t, AppColors.warmIvory), // theirs, from right
                          // Particle burst on the bloom — brand-colour
                          // sparks + confetti. Skipped entirely under
                          // Reduced Motion.
                          if (!reduceMotion && bloom > 0)
                            CustomPaint(
                              size: const Size(280, 280),
                              painter: _BurstPainter(
                                progress: bloom,
                                particles: _particles,
                              ),
                            ),
                          if (t >= 0.98)
                            const Icon(Icons.favorite,
                                color: AppColors.warmIvory, size: 34),
                        ],
                      );
                    },
                  ),
                ),
                _enter(
                  Text(
                    'It\'s a spark',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.warmIvory,
                        ),
                  ),
                  reduceMotion: reduceMotion,
                  delayMs: 380,
                ),
                const SizedBox(height: 6),
                _enter(
                  Text(
                    'You and ${widget.member.firstName} liked each other.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.warmIvory.withValues(alpha: 0.9),
                        ),
                  ),
                  reduceMotion: reduceMotion,
                  delayMs: 460,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: _enter(
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: widget.onSuggestPlan,
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: const Text('Suggest a plan'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onMessage,
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text('Message'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warmIvory,
                                minimumSize: const Size.fromHeight(50),
                                side: const BorderSide(color: AppColors.warmIvory),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onPlayGame,
                              icon: const Icon(Icons.sports_esports_outlined, size: 18),
                              label: const Text('Play a game'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.warmIvory,
                                minimumSize: const Size.fromHeight(50),
                                side: const BorderSide(color: AppColors.warmIvory),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    ),
                    reduceMotion: reduceMotion,
                    delayMs: 560,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// flutter_animate entrance (fade + gentle rise). Under Reduced
  /// Motion the child renders plain — no fade, no travel.
  Widget _enter(
    Widget child, {
    required bool reduceMotion,
    required double delayMs,
  }) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(
          duration: 350.ms,
          delay: delayMs.ms,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.22,
          end: 0,
          duration: 380.ms,
          delay: delayMs.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// One burst particle: a spark dot or a confetti fleck.
class _Particle {
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.delay,
    required this.spin,
    required this.confetti,
  });

  final double angle; // radians
  final double distance; // max travel in px
  final double size;
  final Color color;
  final double delay; // 0..0.3 — staggered start within the bloom
  final double spin; // confetti rotation
  final bool confetti;
}

/// Paints the bloom burst: particles ease out from centre, fading as
/// they travel. [progress] is the bloom curve value (0..1).
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    for (final p in particles) {
      final local = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = 1 - math.pow(1 - local, 2).toDouble(); // easeOutQuad
      final r = p.distance * eased;
      final pos = centre +
          Offset(math.cos(p.angle) * r, math.sin(p.angle) * r - 10 * local);
      paint.color = p.color.withValues(alpha: (1 - local) * 0.95);
      if (p.confetti) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.spin + local * 2.2);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size * 1.7, height: p.size * 0.8),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(pos, p.size * (1 - local * 0.4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
