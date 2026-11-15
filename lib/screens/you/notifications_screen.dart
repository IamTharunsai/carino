import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/notify.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../chats/chat_list_screen.dart';
import '../connect/plans_list_screen.dart';
import 'likes_manager_screen.dart';

/// S-056 Notifications Centre — every row is a REAL event. What's personal
/// is the wording: your language and your tone (models/notify.dart). Tapping
/// a row always goes somewhere (never a dead tap).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.onTarget});

  /// 'connect' | 'chats' | 'plans' — host shell may switch tabs instead.
  final ValueChanged<String>? onTarget;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _prefs = Services.prefs;

  void _open(String target) {
    if (widget.onTarget != null) return widget.onTarget!(target);
    final Widget page = switch (target) {
      'plans' => const PlansListScreen(),
      'connect' => const LikesManagerScreen(),
      _ => const ChatListScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    const items = MockData.notifications;
    final text = Theme.of(context).textTheme;
    final p = NotifPrefs(
      language: _prefs.notifLanguage,
      tone: _prefs.notifTone,
      genericPreviews: _prefs.genericPreviews,
    );
    final noon = DateTime(2026, 1, 1, 12);
    final samples = [
      compose(const NotifEvent(NotifKind.message, who: 'Aria'), p, at: noon, sentToday: 0)!,
      compose(const NotifEvent(NotifKind.planReminder, who: 'Aria', detail: 'Coffee'), p, at: noon, sentToday: 0)!,
    ];
    return GlassScaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Written for you', style: text.titleMedium),
                Text('Only real things — a message, a match, a plan. You choose how they sound.',
                    style: text.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final l in supportedNotifLanguages)
                      ChoiceChip(
                        label: Text(l),
                        selected: _prefs.notifLanguage == l,
                        onSelected: (_) => setState(() => _prefs.notifLanguage = l),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in NotifTone.values)
                      ChoiceChip(
                        label: Text(t == NotifTone.calm ? 'Calm' : 'Playful'),
                        selected: _prefs.notifTone == t,
                        onSelected: (_) => setState(() => _prefs.notifTone = t),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final n in samples)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${n.title} — ${n.body}\nLock screen: ${n.lockScreen}',
                        style: text.bodySmall),
                  ),
                Text('Quiet 22:00–08:00 · at most 5 a day (messages, plans and safety always reach you).',
                    style: text.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Center(child: Text("Nothing yet — we'll only buzz for real things.")),
          for (final n in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassContainer(
                onTap: () => _open(n.target),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icon(n.category), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.text, style: text.bodyMedium),
                          Text(n.timeLabel, style: text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
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
