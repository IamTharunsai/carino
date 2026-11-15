import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/secure_screen.dart';
import '../../data/mock_data.dart';
import '../../models/experience.dart';
import '../../models/member.dart';
import '../../models/message.dart';
import '../../models/sync.dart';
import '../../models/wellbeing.dart' show BookMode;
import '../../widgets/sync_widgets.dart';
import '../connect/decompress_screens.dart' show bookExperience;
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import '../connect/plan_composer_screen.dart';
import '../connect/plan_detail_screen.dart';
import '../connect/spark_session_screen.dart';
import 'conversation_settings_screen.dart';
import 'games_screen.dart';
import 'media_viewer_screen.dart';
import '../experience/experience_screens.dart';

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

  /// Keeps the newest message in view (on open and whenever one is added).
  final ScrollController _scroll = ScrollController();
  int _shown = 0;

  @override
  void dispose() {
    _vanishTimer?.cancel();
    if (_vanish && widget.conversation.vanishMinutes == 0) _dissolveRead();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }
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

  // --- Conversation Sync ----------------------------------------------------
  /// Tone tag for the NEXT message you send (optional).
  ToneTag? _tone;
  bool _bridgeDismissed = false;

  bool get _met => Services.trust.hasMet(_member.id);

  /// iOS reported a screenshot in a Vanish chat: say so to both people.
  /// Live: the server posts the notice (report_screenshot RPC) so the other
  /// person sees it too — clients can't post system notices themselves.
  void _screenshotTaken() {
    Services.backend.reportScreenshot(widget.conversation.id);
    setState(() => widget.conversation.messages.add(ChatMessage(
          id: 'shot-${DateTime.now().millisecondsSinceEpoch}',
          text: 'You took a screenshot — ${_member.firstName} was notified.',
          fromMe: true,
          timeLabel: 'now',
          isSystemNotice: true,
        )));
  }

  /// "I'll message first": my composer waits until they've written.
  String? get _firstHold => firstMessageHold(
        theirs: _member.comfort,
        theyHaveWritten: widget.conversation.messages
            .any((m) => !m.fromMe && !m.isSystemNotice),
        theirName: _member.firstName,
      );

  /// "You both": real overlaps only, minus anything they asked not to discuss.
  List<String> get _chips => commonGround(
        myInterests: Services.prefs.me.interests,
        theirInterests: _member.interests,
        myTastes: Services.prefs.tastesOrSample,
        theirTastes: _member.tasteAnswers,
        theirAvoid: _member.textingStyle.avoid,
      );

  /// A shared chip came up in the chat → a bookable plan for it.
  Bridge? get _bridge => findBridge(
        chips: _chips,
        texts: [
          for (final m in widget.conversation.messages)
            if (!m.isSystemNotice && !m.dissolved && !m.unsent) m.text
        ],
        experiences: MockData.decompress,
      );

  void _showStyle() {
    final hints = styleHints(
        mine: Services.prefs.myStyle,
        theirs: _member.textingStyle,
        name: _member.firstName);
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextingCard(
            title: 'How ${_member.firstName} texts',
            style: _member.textingStyle,
            comfort: _member.comfort,
          ),
          for (final h in hints)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(h, style: Theme.of(context).textTheme.bodySmall),
            ),
          if (Services.prefs.myStyle.isEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Add yours: You tab, How I text & comfort'),
            ),
        ],
      ),
    );
  }

  void _photo({required bool viewOnce}) {
    final hold = photoBlockedReason(
      theirs: _member.comfort,
      daysChatting: widget.conversation.daysChatting,
      met: _met,
      theirName: _member.firstName,
    );
    if (hold != null) {
      showComfortHold(context, hold);
      return;
    }
    _viewOnceNext = viewOnce;
    _sendMedia();
  }

  void _openComposer() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlanComposerScreen(member: _member)),
      );

  void _call() {
    final hold = callBlockedReason(
      mine: Services.prefs.myComfort,
      theirs: _member.comfort,
      met: _met,
      theirName: _member.firstName,
    );
    if (hold != null) {
      showComfortHold(context, hold, onPlan: _openComposer);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SparkPreCallScreen()));
  }

  Future<void> _pickTone() async {
    final t = await showGlassSheet<ToneTag>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tone tag for your next message',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Optional. Helps the message land the way you mean it.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in ToneTag.values)
                ActionChip(
                  label: Text(tag.label),
                  onPressed: () => Navigator.of(context).pop(tag),
                ),
            ],
          ),
        ],
      ),
    );
    if (t != null && mounted) setState(() => _tone = t);
  }

  Future<void> _pause() async {
    final conv = widget.conversation;
    if (conv.pausedLabel != null) {
      setState(() {
        conv.pausedLabel = null;
        conv.messages.add(ChatMessage(
          id: 'resume-${DateTime.now().millisecondsSinceEpoch}',
          text: "You're back — chat resumed.",
          fromMe: true,
          timeLabel: 'now',
          isSystemNotice: true,
        ));
      });
      return;
    }
    final l = await showGlassSheet<PauseLength>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Pause, don't ghost", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            "${_member.firstName} gets a kind note saying you're busy, not gone. "
            'No nudges while paused.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          for (final p in PauseLength.values)
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text('Back ${p.label}'),
              onTap: () => Navigator.of(context).pop(p),
            ),
        ],
      ),
    );
    if (l == null || !mounted) return;
    setState(() {
      conv.pausedLabel = l.label;
      conv.messages.add(ChatMessage(
        id: 'pause-${DateTime.now().millisecondsSinceEpoch}',
        text: pauseNotice(l, name: 'You'),
        fromMe: true,
        timeLabel: 'now',
        isSystemNotice: true,
      ));
    });
    Services.analytics.action('chat_paused');
  }

  bool get _iHaveNotSpoken =>
      !widget.conversation.messages.any((m) => m.fromMe && !m.isGameCard);

  @override
  void initState() {
    super.initState();
    _member = MockData.memberById(widget.conversation.memberId);
    widget.conversation.unreadCount = 0;
    if (_iHaveNotSpoken && _firstHold == null) _loadStarters();
    if (_vanish && widget.conversation.vanishMinutes > 0) {
      _vanishTimer = Timer(Duration(minutes: widget.conversation.vanishMinutes), _dissolveRead);
    }
  }

  Timer? _vanishTimer;

  /// Vanish: everything read in this sitting dissolves (system notices and
  /// game cards stay). In production the server sets dissolved_at.
  void _dissolveRead() {
    if (!_vanish) return;
    for (final m in widget.conversation.messages) {
      if (!m.isSystemNotice && !m.isGameCard) m.dissolved = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadStarters() async {
    // S-032B Conversation Starters: context-aware openers (incl. from any
    // game result — AI-01), always drafts. "Suggest a plan" + "Send a
    // message" sit beside them in the UI.
    // Grounded in "You both" first; AI drafts (also given the overlaps) after.
    final chips = _chips;
    final drafts = Services.prefs.aiIcebreakers
        ? await Services.ai.suggestOpeners(memberName: _member.firstName, shared: chips)
        : const <String>[]; // AI icebreakers off: only the "You both" openers
    if (!mounted) return;
    setState(() => _starters =
        [...groundedOpeners(chips, _member.firstName), ...drafts].take(4).toList());
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

  /// This chat's bubble colour (Chat theme, per conversation).
  Color get _myBubble =>
      chatThemes[Services.prefs.chatThemes[widget.conversation.id] ?? 0].$2;

  Future<void> _pickTheme() async {
    final i = await showChatThemeSheet(
        context, Services.prefs.chatThemes[widget.conversation.id] ?? 0);
    if (i == null || !mounted) return;
    setState(() => Services.prefs.chatThemes[widget.conversation.id] = i);
    Services.analytics.action('chat_theme');
  }

  void _attachMenu() {
    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: AppColors.sparkCoral),
          title: Text(label),
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
        );
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(Icons.photo_outlined, 'Photo', () => _photo(viewOnce: false)),
          item(Icons.visibility_outlined, 'View-once photo', () => _photo(viewOnce: true)),
          item(Icons.theater_comedy_outlined, 'Add a tone tag', _pickTone),
          item(Icons.emoji_emotions_outlined, 'Sticker', _sendSticker),
          item(Icons.mic_none_outlined, 'Voice note', _sendVoiceNote),
          item(Icons.sports_esports_outlined, 'Play a game', () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => GamesScreen(member: _member)),
              )),
          item(Icons.calendar_month_outlined, 'Suggest a plan', _openComposer),
          item(Icons.pause_circle_outline,
              widget.conversation.pausedLabel == null ? 'Pause this chat' : 'Resume chat', _pause),
        ],
      ),
    );
  }

  Future<void> _sendSticker() async {
    final st = await showStickerTray(context);
    if (st == null || !mounted) return;
    setState(() => widget.conversation.messages.add(ChatMessage(
          id: 'sticker-${DateTime.now().millisecondsSinceEpoch}',
          text: st,
          fromMe: true,
          timeLabel: 'now',
        )));
    Services.analytics.action('sticker');
  }

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
        toneTag: _tone?.label,
      ));
      _composer.clear();
      _aiDrafts = const [];
      _tone = null;
    });
  }

  Future<void> _loadAiDrafts() async {
    if (!Services.prefs.aiConversationAssistant) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AI drafts are off. Turn them on in Privacy Centre → AI features.')));
      return;
    }
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
    if (conv.messages.length != _shown) {
      _shown = conv.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
    // Vanish: block screenshots on Android while the chat is open.
    return SecureScreen(enabled: _vanish, onScreenshot: _screenshotTaken, child: GlassScaffold(
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
              Flexible(child: Text(_member.firstName, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Suggest a plan',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlanComposerScreen(member: _member),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Spark video (connections only)',
            onPressed: _call,
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Chat theme',
            onPressed: _pickTheme,
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
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                _syncStrip(context),
                for (final msg in conv.messages) _bubble(context, msg),
              if (_bridge case final b? when !_bridgeDismissed && !_blocked)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GlassContainer(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You both like ${b.chip.toLowerCase()}. ${b.experience.title} · '
                          '${b.experience.timeLabel} · '
                          '${b.experience.priceCents == 0 ? 'Free' : '\$${b.experience.priceCents ~/ 100}'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Wrap(
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _bridgeDismissed = true),
                              child: const Text('Not now'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  bookExperience(context, b.experience, BookMode.date),
                              child: const Text('Book as a date'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
          else if (_firstHold case final hold?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: GlassContainer(
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AppColors.sparkCoral),
                    const SizedBox(width: 8),
                    Expanded(child: Text(hold, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              ),
            )
          else ...[
          if (_tone != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.theater_comedy_outlined, size: 14),
                  label: Text('Tone: ${_tone!.label}'),
                  onDeleted: () => setState(() => _tone = null),
                ),
              ),
            ),
          // Composer.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            child: Row(
              children: [
                // One "+" for attachments keeps the composer roomy.
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add photo, sticker, voice, game',
                  onPressed: _attachMenu,
                ),
                Expanded(
                  child: TextField(
                    controller: _composer,
                    maxLength: 1000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      counterText: '',
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
                  icon: Icon(
                    _aiLoading ? Icons.hourglass_top : Icons.auto_awesome_outlined,
                  ),
                  tooltip: 'Suggest replies (AI drafts)',
                  onPressed: _aiLoading ? null : _loadAiDrafts,
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _composer,
                  builder: (_, v, __) => IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.emberCrimson,
                    tooltip: 'Send',
                    onPressed: v.text.trim().isEmpty ? null : _send,
                  ),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    ));
  }

  /// Pace note + "You both" chips + their style — the "read them right" strip.
  Widget _syncStrip(BuildContext context) {
    final pace = paceNote(_member.firstName, _member.textingStyle);
    final chips = _chips;
    final note = Services.prefs.matchNotes[_member.id];
    final small = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassContainer(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: AppColors.sparkCoral),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(pace ?? 'See how ${_member.firstName} likes to text',
                      style: small, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                TextButton(onPressed: _showStyle, child: const Text('Their style')),
              ],
            ),
            if (chips.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('You both', style: small),
                  for (final c in chips.take(3))
                    Chip(
                      label: Text(c),
                      labelStyle: small?.copyWith(fontWeight: FontWeight.w600),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            // Chemistry streak: visible where you talk, one tap to keep it going.
            Builder(builder: (context) {
              final days = Services.prefs.streaks[_member.id] ?? 0;
              return Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.local_fire_department_outlined, size: 16),
                  label: Text(days > 0
                      ? 'Streak · Day $days — play today to keep it'
                      : 'Start a streak: play a quick game'),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => GamesScreen(member: _member)))
                      .then((_) => mounted ? setState(() {}) : null),
                ),
              );
            }),
            if (note != null && note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
                child: Text('Remember: $note', style: small, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
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
                Flexible(child: Text('Game · ${msg.gameTitle ?? msg.text}')),
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
              ? _myBubble
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
                onTap: () async {
                  if (msg.viewOnce && msg.mediaConsumed) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MediaViewerScreen(message: msg),
                    ),
                  );
                  // S-037: view-once is spent when you close it, not before.
                  if (msg.viewOnce && mounted) setState(() => msg.mediaConsumed = true);
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
                        child: ImageFiltered(
                          enabled: !msg.fromMe && Services.prefs.sensitiveMediaBlur,
                          imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Image.asset(msg.mediaAsset!,
                              width: 200, height: 140, fit: BoxFit.cover),
                        ),
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
            if (msg.toneTag != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warmIvory.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(msg.toneTag!,
                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
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
                Flexible(child: Text(
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
                )),
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
