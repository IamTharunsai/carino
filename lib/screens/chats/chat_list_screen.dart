import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/experience.dart';
import '../../models/message.dart';
import '../../models/social.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'conversation_screen.dart';
import 'social_screens.dart';

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

  /// Friend groups (social Phase 1). Kept in state so new groups stay.
  late final List<GroupChat> _groups = MockData.groups();

  Future<void> _newGroup() async {
    final g = await showNewGroupSheet(context);
    if (g == null || !mounted) return;
    setState(() => _groups.insert(0, g));
    _openGroup(g);
  }

  Future<void> _openGroup(GroupChat g) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GroupChatScreen(group: g)),
    );
    if (mounted) setState(() {});
  }

  /// Conversations closed kindly this session (demo; server state in prod).
  final Set<String> _closed = {};

  void _closeTheLoop(Conversation conv, String firstName) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Close the loop with $firstName?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'A kind goodbye beats silence. Pick one — it sends as you, and '
            'the chat moves to your archive. Nobody gets labelled.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          for (final t in closeTheLoopTemplates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _closed.add(conv.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Sent to $firstName. Chat archived.')),
                  );
                },
                child: Text(t),
              ),
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
    for (final group in _groups) {
      group.removeExpired();
    }
    var conversations =
        MockData.conversations()
            .where((c) => !_closed.contains(c.id))
            .where((c) => !Services.prefs.hiddenChats.contains(c.id))
            .where((c) => !Services.prefs.blocked.contains(c.memberId))
            .toList()
          // Pinned chats first.
          ..sort((a, b) => (Services.prefs.pinnedChats.contains(b.id) ? 1 : 0)
              .compareTo(Services.prefs.pinnedChats.contains(a.id) ? 1 : 0));
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      conversations = conversations.where((c) {
        if (c.mode == ChatMode.vanish) return false; // never indexed
        final member = MockData.memberById(c.memberId);
        return member.name.toLowerCase().contains(q) ||
            c.messages
                .any((m) => !m.dissolved && m.text.toLowerCase().contains(q));
      }).toList();
    }
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Chats',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                icon: const Icon(Icons.people_outline),
                tooltip: 'Friends & circles',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const FriendsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.group_add_outlined),
                tooltip: 'New group',
                onPressed: _newGroup,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'Search groups and Keep chats…',
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
            'Search covers groups and Keep chats — Vanish threads are never indexed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text('Groups', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final g in _groups.where((g) {
            final q = _query.trim().toLowerCase();
            return q.isEmpty ||
                g.name.toLowerCase().contains(q) ||
                g.messages.any((m) => m.text.toLowerCase().contains(q));
          })) ...[
            GlassContainer(
              onTap: () => _openGroup(g),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      children: [
                        for (var i = 0; i < g.memberIds.length && i < 2; i++)
                          Positioned(
                            left: i * 16.0,
                            top: i * 12.0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundImage: AssetImage(
                                  MockData.personById(g.memberIds[i])
                                      .photoAsset),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          g.poll != null
                              ? '🗳 Vote open: ${g.poll!.placeType}'
                              : (g.messages.isEmpty
                                  ? 'Say hello'
                                  : g.messages.last.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (g.unreadCount > 0)
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
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Text('Dates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
              final pinned = Services.prefs.pinnedChats.contains(conv.id);
              return GestureDetector(
                onLongPress: () => _chatMenu(conv.id, member.firstName),
                child: GlassContainer(
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
                              if (pinned)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.push_pin, size: 14, color: AppColors.sparkCoral),
                                ),
                              Flexible(
                                child: Text(member.firstName,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  conv.mode == ChatMode.vanish
                                      ? 'Vanish'
                                      : 'Keep',
                                ),
                                visualDensity: VisualDensity.compact,
                                labelStyle: const TextStyle(fontSize: 11),
                                backgroundColor: conv.mode == ChatMode.vanish
                                    ? AppColors.sparkCoral
                                        .withValues(alpha: 0.18)
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
                          // Close the Loop: optional, kind, never a label
                          // anyone else sees.
                          if (conv.quietDays >= quietDaysThreshold)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () =>
                                  _closeTheLoop(conv, member.firstName),
                              icon: const Icon(Icons.waving_hand_outlined,
                                  size: 14),
                              label: Text(
                                  'Quiet for ${conv.quietDays} days · close kindly?'),
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
              ));
            }),
            const SizedBox(height: 10),
          ],
          if (Services.prefs.hiddenChats.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text('Hidden chats (${Services.prefs.hiddenChats.length})'),
              subtitle: const Text('Unlock with Face, fingerprint or PIN'),
              onTap: _openHidden,
            ),
          Text('Tip: press and hold a chat to pin or hide it.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _chatMenu(String id, String name) {
    final prefs = Services.prefs;
    final pinned = prefs.pinnedChats.contains(id);
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(pinned ? 'Unpin $name' : 'Pin $name to the top'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() => pinned ? prefs.pinnedChats.remove(id) : prefs.pinnedChats.add(id));
              prefs.save();
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: Text('Hide chat with $name'),
            subtitle: const Text("Moves it behind your app lock. They're not told."),
            onTap: () {
              Navigator.of(context).pop();
              setState(() => prefs.hiddenChats.add(id));
              prefs.save();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openHidden() async {
    final ok = await Services.biometric.unlock('Show hidden chats');
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Couldn't unlock. Set up Face, fingerprint or a screen lock on this phone.")));
      return;
    }
    final hidden = MockData.conversations()
        .where((c) => Services.prefs.hiddenChats.contains(c.id))
        .toList();
    await showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in hidden)
            ListTile(
              leading: CircleAvatar(
                  backgroundImage: AssetImage(MockData.memberById(c.memberId).photoAsset)),
              title: Text(MockData.memberById(c.memberId).firstName),
              trailing: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() => Services.prefs.hiddenChats.remove(c.id));
                  Services.prefs.save();
                },
                child: const Text('Unhide'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ConversationScreen(conversation: c)));
              },
            ),
        ],
      ),
    );
  }
}
