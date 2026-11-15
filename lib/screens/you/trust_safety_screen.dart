import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import 'support_screen.dart';

/// S-052 Safety Centre (Trust & Safety Centre).
///
/// Home of the Fold-4 surfaces: the STRUCTURED REPORT TREE entry
/// (SafetyActions.showReportFlow), the APPEALS entry
/// (SafetyActions.showAppealsEntry), and "Your cases" — report + appeal
/// statuses with their SLAs. Plus emergency guidance and safety guides.
///
/// This centre is never paywalled, never hidden by RemoteConfig, and its
/// copy never discourages reporting (blueprint guardrails).
class TrustSafetyScreen extends StatelessWidget {
  const TrustSafetyScreen({super.key});

  static const List<MapEntry<String, String>> _guides = [
    MapEntry(
      'Meeting in public: the first-plan checklist',
      'Public place, daytime or busy evening, your own transport both '
          'ways. Tell a friend where you\'ll be and when you\'ll check '
          'in. Keep the plan in the app until you\'ve met. Leave whenever '
          'you want — no explanation is owed, ever.',
    ),
    MapEntry(
      'Money requests are always a scam — every time',
      'No real date asks for money, gift cards, crypto, or "help with a '
          'ticket home". The moment money appears, stop, screenshot '
          'nothing (the sealed vault already has it), and report — '
          'you will not be the first person they tried.',
    ),
    MapEntry(
      'What verification does and doesn\'t promise',
      'Verified means: a real government ID, age 21+, a live face, and '
          'that the face matches the ID and the profile photo. It does '
          'NOT mean kind, honest, or safe. Verification proves identity — '
          'never character. Keep first plans public.',
    ),
    MapEntry(
      'If a chat moves off-app fast, slow it down',
      'Pressure to move to another app in the first minutes is the '
          'single most common scam opening. Staying here keeps report + '
          'evidence working. Anyone real will understand.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: const Text('Trust & Safety Centre')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Emergency first — always at the top.
          GlassContainer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emergency_outlined,
                    color: AppColors.emberCrimson),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'In immediate danger, call your local emergency number first. This centre is for after you\'re safe.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // S-052: a LIVE incident gets its own front door — same tree,
          // urgent queue, and copy that puts emergency services first.
          SparkButton(
            label: 'Report a live incident',
            icon: Icons.emergency_outlined,
            onPressed: () => SafetyActions.showReportFlow(
              context,
              surface: 'Live incident',
            ),
          ),
          const SizedBox(height: 8),
          SparkButton(
            label: 'Talk to Support',
            icon: Icons.support_agent_outlined,
            secondary: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
            ),
          ),
          const SizedBox(height: 14),
          _action(
            context,
            icon: Icons.flag_outlined,
            title: 'Make a report',
            subtitle: 'Structured categories — routed to human reviewers, 24h SLA',
            onTap: () => SafetyActions.showReportFlow(
              context,
              surface: 'Safety Centre',
            ),
          ),
          _action(
            context,
            icon: Icons.gavel_outlined,
            title: 'Appeal a decision',
            subtitle: 'Warnings, restrictions, removals on YOUR account — human review',
            onTap: () => SafetyActions.showAppealsEntry(context),
          ),
          const SizedBox(height: 8),
          Text('Your cases', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          // INTEGRATION POINT: live case list from BackendService case
          // system (reports + appeals + warning acknowledgments).
          _caseRow(context,
              ref: 'CN-DEMO', kind: 'Report', status: 'In review · due within 24h'),
          _caseRow(context,
              ref: 'CN-A-DEMO', kind: 'Appeal', status: 'Not started — tap Appeal above'),
          const SizedBox(height: 8),
          // Warnings (REA warnings/acknowledge): an active warning can be
          // acknowledged OR appealed from here — both paths stay visible.
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Warnings',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('No active warnings on your account.',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => SafetyActions.showAppealsEntry(context),
                  child: const Text('How appeals work'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Dating safety guides',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final guide in _guides)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => showGlassSheet<void>(
                  context,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guide.key,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(guide.value,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        size: 18, color: AppColors.sparkCoral),
                    const SizedBox(width: 10),
                    Expanded(child: Text(guide.key)),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Help & support: our AI assistant answers first and says it\'s AI in its first message — "Talk to a human" is always one tap away.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.sparkCoral),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _caseRow(
    BuildContext context, {
    required String ref,
    required String kind,
    required String status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$kind · $ref',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(status, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.schedule, size: 16, color: AppColors.sparkCoral),
          ],
        ),
      ),
    );
  }
}
