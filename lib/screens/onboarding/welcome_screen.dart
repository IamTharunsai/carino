import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-001 Welcome / Splash.
/// First-eye rule: the A1 hero carries the feeling at the top of the
/// screen; the logo floats (transparent) in the calm sky; the welcome panel
/// layers over the photo from mid-screen down. Age rules are enforced on
/// the next screen (date of birth), not repeated here.
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
    final size = MediaQuery.of(context).size;
    final imageHeight = size.height * 0.62;
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        children: [
          // A1 hero sits at the TOP (faces + string lights stay in view);
          // the panel layers over its lower part from mid-screen down.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _drift,
                builder: (context, child) => Transform.scale(
                  scale: reduceMotion ? 1.0 : 1.0 + 0.06 * _drift.value,
                  child: child,
                ),
                child: Image.asset(
                  AppConfig.assetHeroWelcome,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.45),
                ),
              ),
            ),
          ),
          // Soft scrims: a light one at the top for the logo, and a fade
          // into Midnight so the photo dissolves into the panel area.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.22, 0.55, 1],
                  colors: [
                    Color(0x8C151014),
                    Color(0x00151014),
                    Color(0x00151014),
                    AppColors.midnight,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              // Transparent logo: the mark floats on the photo, no box.
              child: Image.asset(AppConfig.assetLogo,
                  height: 56, alignment: Alignment.centerLeft),
            ),
          ),
          Positioned(
            top: size.height * 0.5,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Find your kind of spark.',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConfig.tagline,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SparkButton(
                      label: 'Create account',
                      icon: Icons.arrow_forward,
                      iconAtEnd: true,
                      onPressed: widget.onContinue,
                    ),
                    const SizedBox(height: 8),
                    SparkButton(
                      label: 'I already have an account',
                      icon: Icons.person_outline,
                      secondary: true,
                      onPressed: widget.onSignIn,
                    ),
                    const SizedBox(height: 8),
                    // S-001 legal links — reachable BEFORE sign-up.
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final doc in const [
                          'Terms',
                          'Privacy',
                          'Community Guidelines',
                        ]) ...[
                          TextButton(
                            onPressed: () => _legalSheet(context, doc),
                            child: Text(doc,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                          if (doc != 'Community Guidelines')
                            const Text('·',
                                style: TextStyle(color: AppColors.softRose)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
