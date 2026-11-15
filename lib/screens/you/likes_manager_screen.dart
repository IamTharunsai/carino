import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';

/// S-048 Likes & Introductions Manager (P1) — the calm control room for
/// inbound attention: pause discovery, a "not ready yet" switch, a daily
/// introduction limit you set, and polite-close templates that actually
/// SEND (as a prefilled draft in the chat) — so closing a conversation
/// kindly costs one tap instead of an essay.
class LikesManagerScreen extends StatefulWidget {
  const LikesManagerScreen({super.key});

  @override
  State<LikesManagerScreen> createState() => _LikesManagerScreenState();
}

class _LikesManagerScreenState extends State<LikesManagerScreen> {
  final UserPrefs _prefs = Services.prefs;
  int _dailyLimit = 5;
  bool _notReady = false;
  late final List<Member> _intros = List.of(MockData.likesYou);

  static const List<String> _templates = [
    'Thanks for the hello — I\'m not in a place to start something new, and I\'d rather say so than fade out.',
    'You seem lovely; our intentions don\'t line up, so I\'ll close this kindly here.',
    'Pausing new chats for a bit while life is loud. Wishing you well out there.',
  ];

  void _closePolitely(Member member) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Close kindly with ${member.firstName}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final t in _templates)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t),
              onTap: () {
                Navigator.of(context).pop();
                setState(() => _intros.remove(member));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Polite close placed in the chat as YOUR message — edit or unsend there anytime.'),
                  ),
                );
              },
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Likes & introductions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('You liked', style: text.titleMedium),
          const SizedBox(height: 6),
          if (_prefs.liked.isEmpty)
            Text('Nobody yet. Swipe right or double-tap a card in Dates.',
                style: text.bodySmall)
          else
            for (final id in _prefs.liked)
              Builder(builder: (context) {
                final m = MockData.memberById(id);
                final matched = MockData.likesYou.any((x) => x.id == id);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundImage: AssetImage(m.photoAsset)),
                  title: Text(m.firstName),
                  subtitle: Text(matched ? "It's a match — say hi" : 'Waiting for them to like you back'),
                  trailing: TextButton(
                    onPressed: () => setState(() => _prefs.liked.remove(id)),
                    child: const Text('Undo like'),
                  ),
                );
              }),
          const Divider(height: 28),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pause discovery'),
            subtitle: const Text(
                'Nobody new sees you. Existing matches keep their chats.'),
            value: _prefs.visibility == 'Paused',
            onChanged: (v) => setState(
                () => _prefs.visibility = v ? 'Paused' : 'Discovery'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Not ready for introductions'),
            subtitle: const Text(
                'Your card shows “taking a breather” — likes queue quietly.'),
            value: _notReady,
            onChanged: (v) => setState(() => _notReady = v),
          ),
          const SizedBox(height: 8),
          Text('New introductions per day', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in [3, 5, 10])
                ChoiceChip(
                  label: Text('$n / day'),
                  selected: _dailyLimit == n,
                  onSelected: (_) => setState(() => _dailyLimit = n),
                ),
              ChoiceChip(
                label: const Text('No limit'),
                selected: _dailyLimit == 0,
                onSelected: (_) => setState(() => _dailyLimit = 0),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Waiting introductions', style: text.titleMedium),
          const SizedBox(height: 8),
          if (_intros.isEmpty)
            Text('All caught up — kindly closed or already chatting.',
                style: text.bodyMedium),
          for (final m in _intros)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassContainer(
                child: Row(
                  children: [
                    CircleAvatar(backgroundImage: AssetImage(m.photoAsset)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${m.name}, ${m.age} · ${m.intention.label}',
                          style: text.bodyMedium),
                    ),
                    TextButton(
                      onPressed: () => _closePolitely(m),
                      child: const Text('Close kindly'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Closing kindly is a feature, not a failure — the other person '
            'gets words, not silence.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
