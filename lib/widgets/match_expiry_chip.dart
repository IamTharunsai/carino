import 'package:flutter/material.dart';
import '../models/member.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Match expiry / archive display (REA §5.1, folded into MatchConnection).
///
/// HONEST-COPY RULES:
///  - The chip states the REAL server clock ("Expires in 19h") — never a
///    fake resetting countdown, never "hurry before they're gone!" pressure.
///  - Expiry exists to keep everyone's list honest, and the archived state
///    is presented as neutral housekeeping, not a loss or a punishment.
///  - Once a conversation or plan exists, no chip renders at all.
class MatchExpiryChip extends StatelessWidget {
  const MatchExpiryChip({super.key, required this.match});

  final MatchConnection match;

  @override
  Widget build(BuildContext context) {
    if (match.archived) {
      return const Chip(
        avatar: Icon(Icons.archive_outlined, size: 14),
        label: Text('Archived'),
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(fontSize: 12),
      );
    }
    if (!match.isExpiring) return const SizedBox.shrink();
    return Tooltip(
      message:
          'Unmessaged matches move to Archived when the clock ends — no penalty, no pressure. Say hello to keep it live.',
      child: Chip(
        avatar: const Icon(Icons.schedule, size: 14, color: AppColors.sparkCoral),
        label: Text(match.expiresInLabel!),
        visualDensity: VisualDensity.compact,
        labelStyle: const TextStyle(fontSize: 12),
        backgroundColor: AppColors.sparkCoral.withValues(alpha: 0.14),
        side: BorderSide.none,
      ),
    );
  }
}

/// The one-line honest explainer shown above the match list (Connect tab).
class MatchExpiryExplainer extends StatelessWidget {
  const MatchExpiryExplainer({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: AppColors.sparkCoral),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Matches with no conversation expire on the clock shown and move to Archived — so nobody\'s time is wasted, and nobody is ghosted forever.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
