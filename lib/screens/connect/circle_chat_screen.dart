import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/circle.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/intro_card.dart';
import '../../widgets/spark_button.dart';

/// Wave 2 · circle chat + Smart Chat (CROWD-FEATURES #7).
///
/// The group thread inside a circle: plain texts, poll stickers (real
/// votes, one per member, movable), "Ask me" opener stickers (post a
/// topic; questions land as texts and the sticker counts them), and
/// Wingperson intro cards. No public counts anywhere — votes are shown
/// to members only, as counts inside the group, never as leaderboards.
///
/// Demo honesty: messages live in the store on this device; the header
/// says the chat is members-only, and nothing here pretends to sync.
class CircleChatScreen extends StatefulWidget {
  const CircleChatScreen({super.key, required this.circleId});

  final String circleId;

  @override
  State<CircleChatScreen> createState() => _CircleChatScreenState();
}

class _CircleChatScreenState extends State<CircleChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    Services.store.postCircleText(widget.circleId, text);
    _composer.clear();
    _scrollToEnd();
  }

  // ------------------------------------------------------------ sheets

  void _actionsSheet() {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Smart Chat stickers',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Openers that start real conversations inside the circle — '
            'not engagement bait. No counts ever leave this group.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.poll_outlined,
                color: AppColors.sparkCoral),
            title: const Text('Poll'),
            subtitle: const Text('Ask the circle, tap to vote.'),
            onTap: () {
              Navigator.of(context).pop();
              _pollSheet();
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.question_answer_outlined,
                color: AppColors.sparkCoral),
            title: const Text('Ask me'),
            subtitle:
                const Text('Offer a topic — the circle asks, you answer.'),
            onTap: () {
              Navigator.of(context).pop();
              _askMeSheet();
            },
          ),
        ],
      ),
    );
  }

  void _pollSheet() {
    final question = TextEditingController();
    final options = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filled =
              options.where((c) => c.text.trim().isNotEmpty).length;
          final ready = question.text.trim().isNotEmpty && filled >= 2;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New poll', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: question,
                onChanged: (_) => setSheetState(() {}),
                maxLength: 90,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'e.g. Next game night — which day?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              for (var i = 0; i < options.length; i++) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: options[i],
                  onChanged: (_) => setSheetState(() {}),
                  maxLength: 32,
                  decoration: InputDecoration(
                    labelText:
                        i < 2 ? 'Option ${i + 1}' : 'Option ${i + 1} (optional)',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SparkButton(
                label: 'Post poll',
                icon: Icons.poll_outlined,
                onPressed: ready
                    ? () {
                        Services.store.postCirclePoll(
                          widget.circleId,
                          question.text,
                          [for (final c in options) c.text],
                        );
                        Navigator.of(ctx).pop();
                        _scrollToEnd();
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      question.dispose();
      for (final c in options) {
        c.dispose();
      }
    });
  }

  void _askMeSheet() {
    final topic = TextEditingController();
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ask me', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Offer a topic you\'re happy to be asked about. Questions '
              'land here as normal messages — answer the ones you like.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: topic,
              onChanged: (_) => setSheetState(() {}),
              maxLength: 90,
              decoration: const InputDecoration(
                labelText: 'Ask me about…',
                hintText: 'e.g. sourdough starters, 10K training',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Post Ask me',
              icon: Icons.question_answer_outlined,
              onPressed: topic.text.trim().isEmpty
                  ? null
                  : () {
                      Services.store
                          .postCircleAskMe(widget.circleId, topic.text);
                      Navigator.of(ctx).pop();
                      _scrollToEnd();
                    },
            ),
          ],
        ),
      ),
    ).whenComplete(topic.dispose);
  }

  void _askQuestionSheet(CircleMessage msg) {
    final question = TextEditingController();
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ask ${circleMemberName(msg.authorId)}',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('"${msg.askMeTopic}"',
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextField(
              controller: question,
              onChanged: (_) => setSheetState(() {}),
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Your question',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Ask in the circle',
              icon: Icons.send_outlined,
              onPressed: question.text.trim().isEmpty
                  ? null
                  : () {
                      Services.store.askCircleQuestion(msg.id, question.text);
                      Navigator.of(ctx).pop();
                      _scrollToEnd();
                    },
            ),
          ],
        ),
      ),
    ).whenComplete(question.dispose);
  }

  // -------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final circle = store.circleById(widget.circleId);
        if (circle == null) {
          return GlassScaffold(
            appBar: AppBar(title: const Text('Circle chat')),
            body: const Center(child: Text('This circle no longer exists.')),
          );
        }
        final messages = store.circleMessagesFor(circle.id);
        return GlassScaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(circle.name,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${circle.memberCount} members · only members see this chat',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) =>
                      _message(context, messages[i]),
                ),
              ),
              _composerBar(context),
            ],
          ),
        );
      },
    );
  }

  Widget _composerBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Polls and Ask-me stickers',
            onPressed: _actionsSheet,
          ),
          Expanded(
            child: TextField(
              controller: _composer,
              maxLength: 500,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Message the Circle…',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.emberCrimson),
            tooltip: 'Send',
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- messages

  Widget _message(BuildContext context, CircleMessage msg) {
    return switch (msg.kind) {
      CircleMsgKind.system => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              msg.text,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      CircleMsgKind.poll => _pollCard(context, msg),
      CircleMsgKind.askMe => _askMeCard(context, msg),
      CircleMsgKind.intro => _introCard(context, msg),
      CircleMsgKind.text => _textBubble(context, msg),
    };
  }

  Widget _introCard(BuildContext context, CircleMessage msg) {
    // The intro object in the store is the source of truth; the chat
    // message only marks its place. A missing intro renders nothing
    // rather than a fabricated card.
    final intro = Services.store.introById(msg.introId ?? '');
    if (intro == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: IntroCard(intro: intro),
    );
  }

  Widget _authorLine(BuildContext context, CircleMessage msg) {
    if (msg.authorId == 'me') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundImage:
                AssetImage(circleMemberPhoto(msg.authorId)),
          ),
          const SizedBox(width: 5),
          Text(circleMemberName(msg.authorId),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _textBubble(BuildContext context, CircleMessage msg) {
    final mine = msg.authorId == 'me';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _authorLine(context, msg),
          Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 290),
              decoration: BoxDecoration(
                color: mine
                    ? AppColors.emberCrimson
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: mine
                          ? AppColors.warmIvory
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.timeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: (mine ? AppColors.warmIvory : AppColors.softRose)
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms);
  }

  Widget _pollCard(BuildContext context, CircleMessage msg) {
    final theme = Theme.of(context);
    final total = msg.pollTotalVotes;
    final myVote = msg.myPollVote;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _authorLine(context, msg),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll_outlined,
                        size: 16, color: AppColors.sparkCoral),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(msg.text,
                          style: theme.textTheme.titleSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < msg.pollOptions.length; i++) ...[
                  _pollOption(context, msg, i, total, myVote == i),
                  if (i < msg.pollOptions.length - 1)
                    const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'No votes yet — tap an option. One vote each; '
                          'tap your pick again to take it back.'
                      : '$total vote${total == 1 ? '' : 's'} · one each · '
                          'tap to move yours',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pollOption(BuildContext context, CircleMessage msg, int index,
      int total, bool mine) {
    final theme = Theme.of(context);
    final option = msg.pollOptions[index];
    final share = total == 0 ? 0.0 : option.votes / total;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Services.store.voteInCirclePoll(msg.id, index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: mine ? AppColors.emberCrimson : AppColors.softRose,
            width: mine ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (mine)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle,
                        size: 15, color: AppColors.emberCrimson),
                  ),
                Expanded(
                  child: Text(option.label, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  total == 0
                      ? '0'
                      : '${option.votes} · ${(share * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: share,
              minHeight: 5,
              borderRadius: BorderRadius.circular(99),
              color: AppColors.sparkCoral,
              backgroundColor:
                  AppColors.softRose.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _askMeCard(BuildContext context, CircleMessage msg) {
    final theme = Theme.of(context);
    final mine = msg.authorId == 'me';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _authorLine(context, msg),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Chip(
                      label: Text('ASK ME'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.emberCrimson,
                      labelStyle: TextStyle(
                          fontSize: 10, color: AppColors.warmIvory),
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mine
                          ? 'Your opener'
                          : '${circleMemberName(msg.authorId)} is taking questions',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('"${msg.askMeTopic}"',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        msg.questionsAsked == 0
                            ? 'No questions yet'
                            : '${msg.questionsAsked} question${msg.questionsAsked == 1 ? '' : 's'} asked',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    if (!mine)
                      TextButton.icon(
                        icon: const Icon(Icons.question_answer_outlined,
                            size: 16, color: AppColors.sparkCoral),
                        label: const Text('Ask',
                            style: TextStyle(color: AppColors.sparkCoral)),
                        onPressed: () => _askQuestionSheet(msg),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
