import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/circle.dart';
import '../services/services.dart';
import '../theme/app_colors.dart';
import '../screens/chats/conversation_screen.dart';
import 'glass_card.dart';
import 'spark_button.dart';

/// Display name for any member id in circle surfaces ('me' = You).
String circleMemberName(String id) =>
    id == 'me' ? 'You' : MockData.memberById(id).firstName;

/// Photo asset for any member id in circle surfaces.
String circleMemberPhoto(String id) => id == 'me'
    ? MockData.currentUser.photoAsset
    : MockData.memberById(id).photoAsset;

/// Wave 2 · one Wingperson introduction as a card (CROWD-FEATURES #8).
///
/// Renders the intro's REAL state from the store: who introduced whom,
/// the note, and where the acceptances stand. When the signed-in member
/// is a recipient who hasn't answered, Accept / Decline are live; when
/// the intro connects, the card offers the 1:1 chat the store opened.
/// Declines are quiet — no reason is ever shown or asked for.
class IntroCard extends StatelessWidget {
  const IntroCard({super.key, required this.intro});

  final WingIntro intro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = circleMemberName(intro.aId);
    final b = circleMemberName(intro.bId);
    final by = circleMemberName(intro.byId);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_outlined,
                  size: 17, color: AppColors.sparkCoral),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  intro.byId == 'me'
                      ? 'You introduced $a & $b'
                      : '$by introduced $a & $b',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Chip(
                label: Text(intro.status.label),
                visualDensity: VisualDensity.compact,
                labelStyle: const TextStyle(fontSize: 11),
                backgroundColor: intro.status == IntroStatus.connected
                    ? AppColors.emberCrimson
                    : null,
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    AssetImage(circleMemberPhoto(intro.aId)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.favorite,
                    size: 13, color: AppColors.sparkCoral),
              ),
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    AssetImage(circleMemberPhoto(intro.bId)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"${intro.note}"',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _stateArea(context, theme),
        ],
      ),
    );
  }

  Widget _stateArea(BuildContext context, ThemeData theme) {
    final a = circleMemberName(intro.aId);
    final b = circleMemberName(intro.bId);
    switch (intro.status) {
      case IntroStatus.declined:
        return Text(
          'Declined — intros are always optional, and nobody is told why.',
          style: theme.textTheme.bodySmall,
        );
      case IntroStatus.connected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Both said yes — $a and $b are connected.',
              style: theme.textTheme.bodySmall,
            ),
            if (intro.involvesMe) ...[
              const SizedBox(height: 8),
              SparkButton(
                label:
                    'Open chat with ${circleMemberName(intro.otherPartyForMe)}',
                icon: Icons.chat_bubble_outline,
                secondary: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConversationScreen(
                      conversation:
                          Services.store.conversationFor(intro.otherPartyForMe),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      case IntroStatus.pending:
        if (intro.involvesMe && !intro.acceptedByMe) {
          final other = circleMemberName(intro.otherPartyForMe);
          final otherAccepted =
              intro.acceptedIds.contains(intro.otherPartyForMe);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                otherAccepted
                    ? '$other already said yes — your call.'
                    : 'Say yes and, if $other does too, a chat opens. '
                        'Nothing is shared until you both accept.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SparkButton(
                      label: 'Decline',
                      secondary: true,
                      onPressed: () {
                        Services.store.declineIntro(intro.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Declined quietly — they just see "Declined".'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SparkButton(
                      label: 'Accept',
                      icon: Icons.check,
                      onPressed: () {
                        final ok = Services.store.acceptIntro(intro.id);
                        if (!context.mounted || !ok) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              intro.isConnected
                                  ? 'Connected — your chat with $other is open in Chats.'
                                  : 'Accepted — if $other says yes too, a chat opens.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        if (intro.involvesMe && intro.acceptedByMe) {
          return Text(
            'You said yes — waiting on '
            '${circleMemberName(intro.otherPartyForMe)}.',
            style: theme.textTheme.bodySmall,
          );
        }
        // I'm the wingperson (or a bystander member): honest status only.
        final waiting = [
          if (!intro.acceptedIds.contains(intro.aId)) a,
          if (!intro.acceptedIds.contains(intro.bId)) b,
        ];
        return Text(
          waiting.isEmpty
              ? 'Both said yes.'
              : 'Waiting on ${waiting.join(' and ')} — an intro only '
                  'opens when both accept.',
          style: theme.textTheme.bodySmall,
        );
    }
  }
}
