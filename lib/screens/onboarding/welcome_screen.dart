import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
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

class _WelcomeScreenState extends State<WelcomeScreen> {

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

  Widget _photo(String asset, double angle, double dx) => Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 132,
            height: 188,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Color(0x221C1A1F), blurRadius: 18, offset: Offset(0, 8))],
              image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // The welcome page is always the light, white look — even in dark mode.
    return Theme(data: AppTheme.light(), child: Builder(builder: _page));
  }

  Widget _page(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Align(alignment: Alignment.centerLeft, child: Image.asset(AppConfig.assetLogo, height: 40)),
            const SizedBox(height: 28),
            // Real people, real plans — a little fan of photo cards.
            SizedBox(
              height: 210,
              child: Stack(alignment: Alignment.center, children: [
                _photo(AppConfig.assetBackdropDiscover, -0.12, -96),
                _photo(AppConfig.assetBackdropMatch, 0.12, 96),
                _photo(AppConfig.assetHeroWelcome, 0, 0),
                Positioned(
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [BoxShadow(color: Color(0x1A1C1A1F), blurRadius: 12)],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.favorite_rounded, size: 14, color: AppColors.sparkCoral),
                      SizedBox(width: 6),
                      Text("It's mutual", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 32),
            Text('Find your kind\nof spark.', style: t.displaySmall),
            const SizedBox(height: 10),
            Text('Real people, real plans, and a date you’ll actually go on.', style: t.bodyLarge),
            const SizedBox(height: 28),
            SparkButton(
              label: 'Create account',
              icon: Icons.arrow_forward_rounded,
              iconAtEnd: true,
              onPressed: widget.onContinue,
            ),
            const SizedBox(height: 10),
            SparkButton(
              label: 'I already have an account',
              icon: Icons.person_outline_rounded,
              secondary: true,
              onPressed: widget.onSignIn,
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final doc in const ['Terms', 'Privacy', 'Community Guidelines'])
                  TextButton(
                    onPressed: () => _legalSheet(context, doc),
                    child: Text(doc, style: t.bodySmall),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
