import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-001 Welcome / Splash.
/// First-eye rule: the A1 hero carries the feeling; the logo sits in the
/// calm area of the image; the 21+ promise is up front, never buried.
/// Motion: A1 Ken Burns drift (20s, 1.00 -> 1.06) — see note in build.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue, required this.onSignIn});

  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  /// Legal summaries (S-001). The FULL texts are hosted documents (legal
  /// set is a hosting-phase deliverable); the summaries here state the
  /// load-bearing promises and never contradict them.
  void _legalSheet(BuildContext context, String doc) {
    final body = switch (doc) {
      'Terms' =>
        '21+ only. Real identity, stated intentions, mutual consent for '
            'every video session. No harassment, no scams, no money '
            'requests — enforcement by humans, with appeals.',
      'Privacy' =>
        'We store verification RESULTS, never your ID images. Location is '
            'bands, never coordinates shown to anyone. Vanish keeps a '
            'sealed, report-only safety copy so abuse can be evidenced — '
            'that\'s stated in-product, not fine print.',
      _ =>
        'Be the person your profile says you are. Consent is specific '
            'and revocable. Money requests end accounts. Reports are '
            'reviewed by people within 24 hours.',
    };
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Summary — the full $doc text opens in the browser at sign-up '
            'and is linked from Settings.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Ken Burns drift per ANIMATION sheet; static when Reduce Motion is on
    // (checked in build via MediaQuery.disableAnimations).
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _drift,
            builder: (context, child) => Transform.scale(
              scale: reduceMotion ? 1.0 : 1.0 + 0.06 * _drift.value,
              child: child,
            ),
            child: Image.asset(AppConfig.assetHeroWelcome, fit: BoxFit.cover),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xCC151014)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The logo lockup (silhouette mark + wordmark).
                  Image.asset(AppConfig.assetLogo, height: 64, alignment: Alignment.centerLeft),
                  const Spacer(),
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Find your kind of spark.',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConfig.tagline,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined,
                                size: 16, color: AppColors.sparkCoral),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${AppConfig.minimumAge}+ only · every member ID-verified · intentions stated up front',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SparkButton(
                          label: 'Create account',
                          icon: Icons.arrow_forward,
                          onPressed: widget.onContinue,
                        ),
                        const SizedBox(height: 8),
                        SparkButton(
                          label: 'I already have an account',
                          icon: Icons.person_outline,
                          secondary: true,
                          onPressed: widget.onSignIn,
                        ),
                        const SizedBox(height: 12),
                        // S-001 legal links — reachable BEFORE sign-up,
                        // never buried behind the flow.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final doc in const [
                              'Terms',
                              'Privacy',
                              'Community Guidelines',
                            ]) ...[
                              TextButton(
                                onPressed: () => _legalSheet(context, doc),
                                child: Text(doc,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ),
                              if (doc != 'Community Guidelines')
                                const Text('·',
                                    style:
                                        TextStyle(color: AppColors.softRose)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
