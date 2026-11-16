import 'package:flutter/material.dart';

import '../models/agent.dart';
import '../theme/app_colors.dart';

/// Wave 4 · Agent Pre-Screen card (MASTER-BUILD-PLAN A2).
///
/// Renders a [PreScreenSummary] — data computed from the two real
/// profiles by state/pre_screen.dart. The card's job is to EXPLAIN,
/// in plain lines, what was checked before a chat opens: verified or
/// not, intentions aligned or not, the real shared signals, and the
/// safety state. It carries no score and no invented affinity, and it
/// cannot send anything: the human's tap is the only way forward.
class PreScreenCard extends StatelessWidget {
  const PreScreenCard({super.key, required this.summary});

  final PreScreenSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fact_check_outlined,
                size: 18, color: AppColors.sparkCoral),
            const SizedBox(width: 8),
            Text('Before you chat — the pre-screen',
                style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Cariño\'s pre-screen checked the real profile facts. '
          'Agents filter and arrange — you commit.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _row(
          context,
          icon: summary.verified
              ? Icons.verified_outlined
              : Icons.warning_amber_outlined,
          text: summary.verified
              ? 'Verified — ID + liveness + photo match passed'
              : 'Verification not completed — chat stays closed until it is',
          strong: summary.verified,
        ),
        _row(
          context,
          icon: summary.intentionAligned
              ? Icons.favorite_outline
              : Icons.swap_horiz_outlined,
          text: summary.intentionLine,
          strong: summary.intentionAligned,
        ),
        if (summary.sharedSignals.isEmpty)
          _row(
            context,
            icon: Icons.search_outlined,
            text: 'No shared signals on the two profiles — that\'s an '
                'honest blank, not a hidden score.',
            strong: false,
          )
        else
          for (final signal in summary.sharedSignals)
            _row(
              context,
              icon: Icons.check_circle_outline,
              text: signal,
              strong: true,
            ),
        _row(
          context,
          icon: summary.safety == PreScreenSafety.clear
              ? Icons.shield_outlined
              : Icons.block_outlined,
          text: summary.safetyLine,
          strong: summary.safety == PreScreenSafety.clear,
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String text,
    required bool strong,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 17,
              color: strong
                  ? AppColors.sparkCoral
                  : AppColors.softRose),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
