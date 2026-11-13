import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/glass_card.dart';

/// S-056 Notifications Centre (P1) — matches, messages, plans, drops and
/// safety notices in one honest list. No engagement-bait: nothing here is
/// a fake "someone likes you!" — every row is a real event from the data
/// layer, and tapping routes to the tab/surface it belongs to (the host
/// shell listens via [onTarget]).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.onTarget});

  /// 'connect' | 'chats' | 'plans' — host shell may switch tabs.
  final ValueChanged<String>? onTarget;

  @override
  Widget build(BuildContext context) {
    const items = MockData.notifications;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const Center(child: Text('Nothing yet — we\'ll only buzz for real things.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final n in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassContainer(
                      onTap: () => onTarget?.call(n.target),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_icon(n.category), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium),
                                Text(n.timeLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
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

  IconData _icon(String kind) => switch (kind) {
        'match' => Icons.favorite_outline,
        'message' => Icons.chat_bubble_outline,
        'plan' => Icons.event_outlined,
        'drop' => Icons.local_fire_department_outlined,
        'safety' => Icons.shield_outlined,
        _ => Icons.notifications_outlined,
      };
}
