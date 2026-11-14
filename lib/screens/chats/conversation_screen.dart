import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/experience.dart';
import '../../models/member.dart';
import '../../models/message.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import '../connect/plan_composer_screen.dart';
import '../connect/plan_detail_screen.dart';
import 'conversation_settings_screen.dart';
import 'games_screen.dart';
import 'media_viewer_screen.dart';

/// S-035 Conversation (Keep) / S-036 (Vanish) / S-036B Mode Switch.
///
/// Rules wired into this screen:
///  - Mode switch needs BOTH people to agree and is prospective only.
///  - Vanish copy is HONEST: messages dissolve on the timer, screenshots
///    cannot be prevented on any phone (detection + notice only), and a
///    sealed report-only Safety Vault copy exists so abuse can be evidenced.
///  - AI-01 suggestions render as DRAFTS above the composer. Tapping one
///    fills the composer — the member edits and sends it THEMSELVES.
///  - Report is in the header overflow. Never paywalled.
///  - Read receipts ("Seen") are a Plus entitlement (REA §5.10) — stubbed
///    here as a display toggle, resolved by PaymentsService in production.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _composer = TextEditingController();
  late final Member _member;
  List<String> _aiDrafts = const [];
  bool _aiLoading = false;

  /// S-035: after a block, the conversation renders a calm tombstone and
  /// the composer disappears — no error, no drama.
  bool _blocked = false;

  /// S-035: view-once applies to the NEXT media you send.
  bool _viewOnceNext = false;

  /// Scam Shield: a calm card for BOTH people when money, crypto, gift
  /// cards or a fast move off-app comes up. A signal, never a verdict.
  bool _shieldDismissed = false;

  Set<ScamSignal> get _signals => {
        for (final m in widget.conversation.messages)
          if (!m.dissolved && !m.unsent && !m.isSystemNotice)
            ...scanForScam(m.text),
      };

  /// S-032B: starters shown until you've sent your first message.
  List<String> _starters = const [];

  bool get _iHaveNotSpoken =>
      !widget.conversation.messages.any((m) => m.fromMe && !m.isGameCard);

  @override
  void initState() {
    super.initState();
    _member = MockData.memberById(widget.conversation.memberId);
    widget.conversation.unreadCount = 0;
    if (_iHaveNotSpoken) _loadStarters();
  }

  Future<void> _loadStarters() async {
    // S-032B Conversation Starters: context-aware openers (incl. from any
    // game result — AI-01), always drafts. "Suggest a plan" + "Send a
    // message" sit beside them in the UI.
    final drafts =
        await Services.ai.suggestOpeners(memberName: _member.firstName);
    if (!mounted) return;
    setState(() => _starters = drafts);
  }

  void _sendMedia() {
    setState(() {
      widget.conversation.messages.add(ChatMessage(
        id: 'local-media-${DateTime.now().millisecondsSinceEpoch}',
        text: _viewOnceNext ? 'View-once photo' : 'Photo',
        fromMe: true,
        timeLabel: 'now',
        mediaAsset: 'assets/images/backdrop_match.jpg',
        viewOnce: _viewOnceNext,
      ));
      _viewOnceNext = false;
    });
  }

  void _sendVoiceNote() {
    // INTEGRATION POINT: recorder -> audio upload. Scaffold adds the
    // message card so the thread shape is real.
    setState(() {
      widget.conversation.messages.add(ChatMessage(
        id: 'local-voice-${DateTime.now().millisecondsSinceEpoch}',
        text: '🎙 Voice note · 0:12',
        fromMe: true,
        timeLabel: 'now',
      ));
    });
  }

  bool get _vanish => widget.conversation.mode == ChatMode.vanish;

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    // Pre-send pause when YOU are about to talk money — a moment to think,
    // never a block. Off-app mentions just raise the shield card.
    final mine = scanForScam(text);
    if (mine.contains(ScamSignal.money) ||
        mine.contains(ScamSignal.crypto) ||
        mine.contains(ScamSignal.giftCards)) {
      final go = await showGlassSheet<bool>(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Before you send', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(scamShieldCopy(mine),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Edit message',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send anyway'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    setState(() {
      widget.conversation.messages.add(ChatMessage(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        fromMe: true,
        timeLabel: 'now',
      ));
      _composer.clear();
      _aiDrafts = const [];
    });
  }

  Future<void> _loadAiDrafts() async {
    // AI-01: suggestions are drafts — see honesty rules in AIService.
    setState(() => _aiLoading = true);
    final drafts = await Services.ai.suggestOpeners(memberName: _member.firstName);
    if (!mounted) return;
    setState(() {
      _aiLoading = false;
      _aiDrafts = drafts;
    });
  }

  void _proposeModeSwitch() {
    // S-036B: proposal goes to BOTH; both must agree; prospective only.
    final target = _vanish ? ChatMode.keep : ChatMode.vanish;
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Switch to ${target == ChatMode.vanish ? 'Vanish' : 'Keep'} mode?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            target == ChatMode.vanish
                ? 'If ${_member.firstName} agrees, NEW messages will dissolve ${widget.conversation.vanishMinutes} minutes after being read. Existing messages stay as they are. Screenshots can\'t be blocked on any phone — if one is detected, you\'ll be told.'
                : 'If ${_member.firstName} agrees, new messages will be kept like a normal chat. Anything already dissolved stays dissolved.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Services.sound.gentleHaptic(); // steady haptic only, per ANIMATION sheet
              Navigator.of(context).pop();
              // SCAFFOLD: demo applies immediately. PRODUCTION: sends a
              // proposal; the mode flips only on the other member's accept,
              // and BOTH clients render the banner at the same moment.
              setState(() => widget.conversation.mode = target);
            },
            child: const Text('Send proposal (demo: applies now)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    return GlassScaffold(
      appBar: AppBar(
        title: GestureDetector(
          // S-038: tapping the person opens Conversation Settings.
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationSettingsScreen(
                conversation: widget.conversation,
                member: _member,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 16, backgroundImage: AssetImage(_member.photoAsset)),
              const SizedBox(width: 8),
              Text(_member.firstName),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Suggest a plan (S-039)',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlanComposerScreen(member: _member),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Spark video (connections only)',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'Safety and conversation settings',
            onPressed: () => SafetyActions.showForMember(
              context,
              member: _member,
              surface: 'Chat',
              onBlocked: () => setState(() => _blocked = true),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode banner + plan pin.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(_vanish ? Icons.timer_outlined : Icons.lock_outline,
                      size: 16, color: AppColors.sparkCoral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _vanish
                          ? 'Vanish · new messages dissolve ${conv.vanishMinutes} min after reading'
                          : 'Keep · messages stay until either of you deletes them',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _proposeModeSwitch,
                    child: const Text('Switch'),
                  ),
                ],
              ),
            ),
          ),
          if (conv.planPinned)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlanDetailScreen(
                      member: _member,
                      placeType: 'Coffee',
                      timeLabel: 'Sat · 11:00',
                      confirmed: true,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 16, color: AppColors.sparkCoral),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Pinned plan: Coffee · Sat 11:00 · both confirmed'),
                    ),
                    Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
          if (_signals.isNotEmpty && !_shieldDismissed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 18, color: AppColors.sparkCoral),
                        const SizedBox(width: 8),
                        Text('Scam Shield',
                            style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(scamShieldCopy(_signals),
                        style: Theme.of(context).textTheme.bodySmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => SafetyActions.showReportFlow(context,
                              member: _member, surface: 'Chat (Scam Shield)'),
                          child: const Text('Report'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _shieldDismissed = true),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                for (final msg in conv.messages) _bubble(context, msg),
              ],
            ),
          ),
          // AI draft panel (AI-01) — drafts only, clearly labelled.
          if (_aiDrafts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: GlassContainer(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_outlined,
                            size: 14, color: AppColors.sparkCoral),
                        const SizedBox(width: 6),
                        Text('AI drafts — tap to edit, you send it',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final draft in _aiDrafts)
                      ActionChip(
                        label: Text(draft, overflow: TextOverflow.ellipsis),
                        onPressed: () => setState(() => _composer.text = draft),
                      ),
                  ],
                ),
              ),
            ),
          // S-032B starters — until your first message.
          if (!_blocked && _iHaveNotSpoken && _starters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: GlassContainer(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Starters — tap one into the composer, make it yours',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final st in _starters)
                          ActionChip(
                            label: Text(st, overflow: TextOverflow.ellipsis),
                            onPressed: () =>
                                setState(() => _composer.text = st),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_month_outlined,
                              size: 14),
                          label: const Text('Suggest a plan instead'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PlanComposerScreen(member: _member),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_blocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: GlassContainer(
                child: Text(
                  'You blocked ${_member.firstName}. This conversation is '
                  'closed — they can\'t contact you, and nothing here is '
                  'visible to them. Unblock from Privacy Centre if you '
                  'ever change your mind.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
          // Composer.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.sports_esports_outlined),
                  tooltip: 'Play a game',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GamesScreen(member: _member),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_outlined),
                  tooltip: _viewOnceNext
                      ? 'Send a view-once photo'
                      : 'Send a photo',
                  color: _viewOnceNext ? AppColors.sparkCoral : null,
                  onPressed: _sendMedia,
                ),
                IconButton(
                  icon: Icon(_viewOnceNext
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  tooltip: 'View-once for next media',
                  onPressed: () =>
                      setState(() => _viewOnceNext = !_viewOnceNext),
                ),
                IconButton(
                  icon: const Icon(Icons.mic_none_outlined),
                  tooltip: 'Voice note',
                  onPressed: _sendVoiceNote,
                ),
                IconButton(
                  icon: Icon(
                    _aiLoading ? Icons.hourglass_top : Icons.auto_awesome_outlined,
                  ),
                  tooltip: 'Suggest replies (AI drafts)',
                  onPressed: _aiLoading ? null : _loadAiDrafts,
                ),
                Expanded(
                  child: TextField(
                    controller: _composer,
                    decoration: InputDecoration(
                      hintText: 'Message ${_member.firstName}…',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, ChatMessage msg) {
    if (msg.isGameCard) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports_outlined,
                    size: 16, color: AppColors.sparkCoral),
                const SizedBox(width: 8),
                Text('Game · ${msg.gameTitle ?? msg.text}'),
              ],
            ),
          ),
        ),
      );
    }
    // S-036 system notices render centred (e.g. screenshot DETECTED —
    // detection only, the copy never claims prevention).
    if (msg.isSystemNotice) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 14, color: AppColors.sparkCoral),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(msg.text,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final mine = msg.fromMe;
    final bubble = Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.emberCrimson
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.unsent)
              const Text('Message unsent',
                  style: TextStyle(fontStyle: FontStyle.italic))
            else if (msg.mediaAsset != null)
              GestureDetector(
                onTap: () {
                  // S-037: opening view-once media consumes it.
                  if (msg.viewOnce) {
                    setState(() => msg.mediaConsumed = true);
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MediaViewerScreen(message: msg),
                    ),
                  );
                },
                child: msg.viewOnce && msg.mediaConsumed
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_off_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('View-once · opened'),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(msg.mediaAsset!,
                            width: 200, height: 140, fit: BoxFit.cover),
                      ),
              )
            else
              Text(
                msg.dissolved ? 'This message dissolved.' : msg.text,
                style: TextStyle(
                  color: mine
                      ? AppColors.warmIvory
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontStyle: msg.dissolved ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (msg.reaction != null) ...[
                  Text(msg.reaction!, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 6),
                ],
                Text(
                  // "Seen" renders only per read-receipt prefs/entitlement;
                  // scaffold shows time (+ vanish expiry where it applies).
                  _vanish && msg.expiresInLabel != null
                      ? '${msg.timeLabel} · ${msg.expiresInLabel}'
                      : msg.timeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: (mine ? AppColors.warmIvory : AppColors.softRose)
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    // S-035 long-press: react, unsend (own, within limits), report.
    return GestureDetector(
      onLongPress: msg.unsent ? null : () => _messageMenu(msg),
      child: bubble,
    );
  }

  void _messageMenu(ChatMessage msg) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final r in ['❤️', '👍', '😂', '😮'])
                IconButton(
                  icon: Text(r, style: const TextStyle(fontSize: 22)),
                  tooltip: 'React $r',
                  onPressed: () {
                    setState(() => msg.reaction = r);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          if (msg.fromMe)
            ListTile(
              leading: const Icon(Icons.undo_outlined),
              title: const Text('Unsend'),
              subtitle: const Text(
                  'Within the window, this becomes “Message unsent” for both of you.'),
              onTap: () {
                setState(() => msg.unsent = true);
                Navigator.of(context).pop();
              },
            ),
          if (!msg.fromMe && msg.mediaAsset == null)
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Translate'),
              onTap: () async {
                Navigator.of(context).pop();
                final out = await Services.ai.translate(msg.text);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  duration: const Duration(seconds: 6),
                  content: Text(out == null
                      ? 'Translation runs on the live AI service, which isn\'t connected in this demo.'
                      : 'Translated: $out'),
                ));
              },
            ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report this conversation'),
            onTap: () {
              Navigator.of(context).pop();
              SafetyActions.showReportFlow(context,
                  member: _member, surface: 'Chat message');
            },
          ),
        ],
      ),
    );
  }
}
