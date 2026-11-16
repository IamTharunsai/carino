import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../state/pre_screen.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/pre_screen_card.dart';
import '../../widgets/spark_button.dart';

/// Wave 4 · Agent Pre-Screen (MASTER-BUILD-PLAN A2) — the gate
/// between a match and its chat.
///
/// Reached from the match celebration's "Message" action and from a
/// Connect match row that has no conversation yet. The summary is
/// computed live from the two real profiles; the ONLY way into the
/// chat is the human's "Start chatting" tap ([onStartChat]) — the
/// agent never sends a message, an opener, or a nudge. A blocked
/// summary renders without the button at all.
class PreScreenScreen extends StatelessWidget {
  const PreScreenScreen({
    super.key,
    required this.member,
    required this.onStartChat,
  });

  final Member member;

  /// Opens the real conversation — supplied by the call site, which
  /// owns navigation (Discover's celebration, Connect's match row).
  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = buildPreScreen(
      me: MockData.currentUser,
      other: member,
      blockedIds: Services.store.blockedIds,
    );
    return GlassScaffold(
      appBar: AppBar(title: Text('Meet ${member.firstName}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(member.photoAsset),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${member.name}, ${member.age}',
                        style: theme.textTheme.titleLarge),
                    Text(
                      '${member.distanceBand} · ${member.city} · '
                      '${member.intention.label}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(child: PreScreenCard(summary: summary)),
          const SizedBox(height: 18),
          if (summary.canChat) ...[
            SparkButton(
              label: 'Start chatting',
              icon: Icons.chat_bubble_outline,
              onPressed: onStartChat,
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing has been sent. The first message is yours to '
              'write — or skip entirely.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ] else
            Text(
              'This match can\'t open a chat. If this looks wrong, '
              'Trust & Safety can review it from the You tab.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
