import 'package:flutter/material.dart';
import '../config/env.dart';
import '../models/creator.dart';
import '../services/services.dart';
import '../theme/app_colors.dart';

/// Send a gift with credits; top up with a small credit pack if needed.
Future<void> showGiftSheet(BuildContext context, String toName) {
  final prefs = Services.prefs;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (s) => StatefulBuilder(
      builder: (s, set) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Send $toName a gift 🎁', style: Theme.of(s).textTheme.titleLarge),
            Text('You have ${prefs.credits} credits', style: Theme.of(s).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final g in giftMenu)
                ActionChip(
                  avatar: Text(g.emoji),
                  label: Text('${g.name} · ${g.credits}'),
                  onPressed: () {
                    if (prefs.credits < g.credits) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not enough credits — grab a pack below.')));
                      return;
                    }
                    prefs.credits -= g.credits;
                    prefs.save();
                    Navigator.pop(s);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${g.emoji} sent to $toName. They’ll love it.')));
                  },
                ),
            ]),
            const Divider(height: 28),
            Text('Get credits', style: Theme.of(s).textTheme.titleSmall),
            for (final p in creditPacks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.toll_outlined, color: AppColors.sparkCoral),
                title: Text('${p.credits} credits'),
                trailing: Text(p.price),
                onTap: () {
                  if (Env.useMockBackend) {
                    set(() => prefs.credits += p.credits);
                    prefs.save();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Credits are bought through the App Store or Google Play. '
                            "They aren't on sale in this build yet — nothing was charged.")));
                  }
                },
              ),
          ]),
        ),
      ),
    ),
  );
}
