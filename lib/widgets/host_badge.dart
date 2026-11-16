import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wave 3 · Micro-Hosts (CROWD-FEATURES #14): the Host badge.
///
/// Rendered ONLY from the store's real hosted-plan count (the parent
/// checks AppStore.isHost) — hosting a plan earns it, nothing else
/// does, and it is never sold or seeded onto a profile that hasn't
/// hosted. [plansHosted] shows the real count when provided.
class HostBadge extends StatelessWidget {
  const HostBadge({super.key, this.plansHosted});

  /// Real hosted-plan count from AppStore.hostedPlanCount; null hides
  /// the count and shows the badge alone.
  final int? plansHosted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emberCrimson.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.sparkCoral.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.house_outlined,
              size: 13, color: AppColors.sparkCoral),
          const SizedBox(width: 4),
          Text(
            plansHosted == null
                ? 'Host'
                : 'Host · $plansHosted plan${plansHosted == 1 ? '' : 's'} hosted',
            style: const TextStyle(
              color: AppColors.sparkCoral,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
