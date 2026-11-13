import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/message.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'conversation_screen.dart';

/// S-034 Chat List. Keep/Vanish badge per conversation; unread dots are
/// REAL counts only. Archived-match conversations don't appear here —
/// archive is a match state (Connect tab), not a chat punishment.
///
/// SEARCH (S-034 rule): the search field indexes KEEP conversations only.
/// Vanish threads are never searchable — disappearing messages that a
/// search index remembers would be a lie about what Vanish means.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    var conversations = MockData.conversations();
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      conversations = conversations.where((c) {
        if (c.mode == ChatMode.vanish) return false; // never indexed
        final member = MockData.memberById(c.memberId);
        return member.name.toLowerCase().contains(q) ||
            c.messages.any(
                (m) => !m.dissolved && m.text.toLowerCase().contains(q));
      }).toList();
    }
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text('Chats', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'Search Keep conversations…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 6),
          Text(
            'Search covers Keep chats only — Vanish threads are never indexed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (_query.trim().isNotEmpty && conversations.isEmpty)
            GlassContainer(
              child: Text(
                'No Keep conversations match “$_query”.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (conversations.isEmpty)
            GlassContainer(
              child: Text(
                'No conversations yet. When a match says hello — or you do — it lands here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          for (final conv in conversations) ...[
            Builder(builder: (context) {
              final member = MockData.memberById(conv.memberId);
              final last = conv.messages.isEmpty ? null : conv.messages.last;
              return GlassContainer(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConversationScreen(conversation: conv),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: AssetImage(member.photoAsset),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(member.firstName,
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  conv.mode == ChatMode.vanish ? 'Vanish' : 'Keep',
                                ),
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(fontSize: 11),
                                backgroundColor: conv.mode == ChatMode.vanish
                                    ? AppColors.sparkCoral.withValues(alpha: 0.18)
                                    : null,
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                          Text(
                            last == null
                                ? 'Say hello'
                                : (last.isGameCard
                                    ? '🎲 ${last.gameTitle ?? 'Game'}'
                                    : last.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (conv.unreadCount > 0)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.emberCrimson,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
