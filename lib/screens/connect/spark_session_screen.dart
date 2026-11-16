import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../services/video_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/state_kit.dart';
import '../chats/games_screen.dart';
import '../discover/profile_detail_screen.dart';

/// S-026 Spark Lobby → S-027 Invite → S-028 Preview, in one pre-call screen.
///
/// THE RULE (Apple 1.2 + Bible): you see the FULL profile first; BOTH people
/// accept; only then can a camera open. There is no anonymous or random
/// video anywhere in this app, and VideoService refuses non-mutual tokens.
class SparkPreCallScreen extends StatefulWidget {
  const SparkPreCallScreen({super.key});

  @override
  State<SparkPreCallScreen> createState() => _SparkPreCallScreenState();
}

class _SparkPreCallScreenState extends State<SparkPreCallScreen> {
  bool _backgroundBlur = true;
  bool _inPool = true;
  bool _cameraOn = true;
  bool _showDenied = false;
  bool _micTesting = false;
  double _micLevel = 0;
  Timer? _micTimer;

  /// S-027: the invite's real response window. Server-issued in
  /// production; the scaffold runs the same countdown locally so the
  /// state (and its quiet expiry) is real UI, not a painted number.
  late final DateTime _inviteExpires =
      DateTime.now().add(const Duration(minutes: 10));
  Timer? _countdown;

  Member get _inviter => MockData.memberById('m-aria');

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _micTimer?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    final d = _inviteExpires.difference(DateTime.now());
    if (d.isNegative) return 'Expired';
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _testMic() {
    setState(() => _micTesting = true);
    var tick = 0;
    _micTimer?.cancel();
    _micTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted) return;
      tick++;
      setState(() => _micLevel = (tick % 5) / 4);
      if (tick >= 10) {
        t.cancel();
        setState(() {
          _micTesting = false;
          _micLevel = 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inviter = _inviter;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Spark Session')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // --- S-026 Lobby: how Spark works, eligibility, your prefs ---
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How Spark works',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final step in const [
                  '1 · You see their FULL profile first — no cold video.',
                  '2 · Both people accept. Only then can a camera open.',
                  '3 · 10 easy minutes. Report + Leave stay on screen.',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(step,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                const Divider(),
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.sparkCoral),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          'You\'re eligible: verified · 21+ · no open restrictions'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I\'m in the Spark pool'),
                  subtitle: const Text(
                      'Matches can invite you during Spark windows.'),
                  value: _inPool,
                  onChanged: (v) => setState(() => _inPool = v),
                ),
                Text(
                  'Your Spark prefs: video-first matches · blur background '
                  'default · windows ${Services.remoteConfig.nextSparkWindowLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('A Spark invite for you',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Chip(
                      avatar: const Icon(Icons.timer_outlined, size: 14),
                      label: Text(_countdownLabel),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${inviter.firstName} saw your profile and invited you to a short video intro. If the timer runs out, the invite just expires — nobody is told you "ignored" it.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(inviter.photoAsset),
                  ),
                  title: Text('${inviter.name}, ${inviter.age}'),
                  subtitle: Text('${inviter.intention.label} · Verified'),
                  trailing: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfileDetailScreen(member: inviter),
                      ),
                    ),
                    child: const Text('Full profile'),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => SafetyActions.showForMember(
                      context,
                      member: inviter,
                      surface: 'Spark invite',
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('Report this invite'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // S-028: own preview + readiness checks before any accept.
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your preview',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (_showDenied)
                  const PermissionDeniedState(
                    permissionLabel: 'Camera',
                    whyNeeded:
                        'Spark needs your camera. Watch-only Sparks don\'t exist here — both cameras, or a polite rain-check instead.',
                  )
                else
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_cameraOn)
                            Image.asset(MockData.currentUser.photoAsset,
                                fit: BoxFit.cover)
                          else
                            Container(
                              color: AppColors.midnight,
                              child: const Center(
                                child: Icon(Icons.videocam_off_outlined,
                                    color: AppColors.softRose, size: 36),
                              ),
                            ),
                          if (_backgroundBlur && _cameraOn)
                            Container(
                                color: Colors.black.withValues(alpha: 0.15)),
                          Center(
                            child: Text(
                              _cameraOn
                                  ? 'Your camera'
                                  : 'Camera off — they\'ll see this too',
                              style:
                                  const TextStyle(color: AppColors.warmIvory),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Blur my background'),
                  value: _backgroundBlur,
                  onChanged: (v) => setState(() => _backgroundBlur = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Camera on'),
                  value: _cameraOn,
                  onChanged: (v) => setState(() => _cameraOn = v),
                ),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: AppColors.sparkCoral),
                    const SizedBox(width: 6),
                    const Text('Camera OK'),
                    const SizedBox(width: 14),
                    TextButton.icon(
                      onPressed: _micTesting ? null : _testMic,
                      icon: const Icon(Icons.mic_none_outlined, size: 16),
                      label: Text(_micTesting ? 'Say something…' : 'Test mic'),
                    ),
                    if (_micTesting)
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _micLevel,
                          color: AppColors.sparkCoral,
                        ),
                      )
                    else
                      const Text('Mic OK'),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    // Scaffold affordance: preview the S-059 denied state.
                    onPressed: () => setState(() => _showDenied = !_showDenied),
                    child: Text(_showDenied
                        ? 'Back to preview'
                        : 'Preview the permission-denied state'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Report and Leave stay on screen for the whole call. Recordings are never made by the app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SparkButton(
            label: 'Accept — start Spark',
            icon: Icons.videocam_outlined,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => SparkCallScreen(member: inviter),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SparkButton(
            label: 'Decline politely',
            icon: Icons.close,
            secondary: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// S-029 Live Spark (mock) → S-032 Post-Call Choice.
/// INTEGRATION POINT: VideoService.joinDemoSession() is replaced by the
/// WebRTC provider room join using a server-minted MUTUAL token.
class SparkCallScreen extends StatefulWidget {
  const SparkCallScreen({super.key, required this.member});

  final Member member;

  @override
  State<SparkCallScreen> createState() => _SparkCallScreenState();
}

class _SparkCallScreenState extends State<SparkCallScreen> {
  final VideoService _video = Services.video;
  Timer? _timer;
  int _seconds = 0;
  bool _muted = false;
  bool _cameraOn = true;
  bool _blur = true;
  bool _captions = false;
  bool _connecting = true;

  /// Fun AR lens for THIS call only (Snapchat energy, dating-safe).
  /// Lenses never touch profile media or verification, include no
  /// face-reshaping or skin-smoothing filters, and anyone wearing one is
  /// labelled "Lens on" for the other person. INTEGRATION POINT: the RTC
  /// provider's video-effects pipeline; the demo overlays the emoji.
  String? _lens;
  static const List<(String, String)> _lenses = [
    ('🎉', 'Party'),
    ('🌧️', 'Rainy day'),
    ('🎲', 'Game night'),
    ('🕶️', 'Shades'),
    ('✨', 'Sparkle'),
  ];

  @override
  void initState() {
    super.initState();
    _video.joinDemoSession().then((_) {
      if (!mounted) return;
      setState(() => _connecting = false);
      Services.sound
          .tapHaptic(); // haptic-led connect cue; no ringtone imitation
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video.leave();
    super.dispose();
  }

  String get _clock =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  Future<void> _endCall() async {
    _timer?.cancel();
    await _video.leave();
    if (!mounted) return;
    // S-032: private choice — connection forms ONLY if both choose Connect.
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How was that spark?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Your choice is private. A chat opens only if you BOTH choose Connect — no one is told a "no".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SparkButton(
            label: 'Connect — open chat',
            icon: Icons.chat_bubble_outline,
            onPressed: () {
              Navigator.of(context).pop(); // sheet
              Navigator.of(context).pop(); // call
            },
          ),
          const SizedBox(height: 8),
          SparkButton(
            label: 'Pass, kindly',
            icon: Icons.close,
            secondary: true,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _pickLens() {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Lenses', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Just for fun, just for this call. ${widget.member.firstName} sees a '
            '"Lens on" label. No beauty or face-changing filters, ever.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('No lens'),
                selected: _lens == null,
                onSelected: (_) {
                  setState(() => _lens = null);
                  Navigator.of(context).pop();
                },
              ),
              for (final (emoji, name) in _lenses)
                ChoiceChip(
                  label: Text('$emoji $name'),
                  selected: _lens == emoji,
                  onSelected: (_) {
                    setState(() => _lens = emoji);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.member.photoAsset, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.2)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _connecting
                              ? 'Connecting…'
                              : '${widget.member.firstName} · $_clock',
                          style: const TextStyle(
                              color: AppColors.warmIvory,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Quality indicator — from the RTC stats stream in
                      // production; labelled sample state in the scaffold.
                      const Chip(
                        avatar: Icon(Icons.signal_cellular_alt, size: 13),
                        label: Text('HD · Good'),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      // Block + Report stay reachable DURING the call (S-029).
                      IconButton(
                        icon:
                            const Icon(Icons.block, color: AppColors.warmIvory),
                        tooltip: 'Block',
                        onPressed: () => SafetyActions.showBlockConfirmation(
                          context,
                          member: widget.member,
                          onBlocked: () => Navigator.of(context).pop(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flag_outlined,
                            color: AppColors.warmIvory),
                        tooltip: 'Report',
                        onPressed: () => SafetyActions.showForMember(
                          context,
                          member: widget.member,
                          surface: 'Spark call',
                        ),
                      ),
                    ],
                  ),
                ),
                // In-call toggles: background blur, live captions, lenses.
                // Wrap (not Row) so the chips reflow on narrow phones.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('Blur background'),
                        selected: _blur,
                        onSelected: (v) => setState(() => _blur = v),
                        visualDensity: VisualDensity.compact,
                      ),
                      FilterChip(
                        label: const Text('Captions'),
                        selected: _captions,
                        onSelected: (v) => setState(() => _captions = v),
                        visualDensity: VisualDensity.compact,
                      ),
                      ActionChip(
                        avatar: Text(_lens ?? '🙂'),
                        label: Text(_lens == null ? 'Lenses' : 'Lens on'),
                        visualDensity: VisualDensity.compact,
                        onPressed: _pickLens,
                      ),
                      if (_captions)
                        const Text(
                          'Live captions on (sample line).',
                          style: TextStyle(
                              color: AppColors.warmIvory, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_connecting)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.sparkCoral),
                      SizedBox(height: 12),
                      Text('Joining your Spark…',
                          style: TextStyle(color: AppColors.warmIvory)),
                    ],
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GlassIconButton(
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        semanticLabel: _muted ? 'Unmute' : 'Mute',
                        onPressed: () => setState(() => _muted = !_muted),
                      ),
                      GlassIconButton(
                        icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                        semanticLabel: _cameraOn ? 'Camera off' : 'Camera on',
                        onPressed: () => setState(() => _cameraOn = !_cameraOn),
                      ),
                      GlassIconButton(
                        icon: Icons.sports_esports_outlined,
                        semanticLabel: 'Play a game on the call',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GamesScreen(member: widget.member),
                          ),
                        ),
                      ),
                      GlassIconButton(
                        icon: Icons.call_end,
                        semanticLabel: 'Leave call',
                        filled: true,
                        onPressed: _endCall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Self picture-in-picture — your own preview, always visible.
          Positioned(
            right: 14,
            bottom: 110,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _cameraOn
                  ? Stack(
                      children: [
                        Image.asset(
                          MockData.currentUser.photoAsset,
                          width: 84,
                          height: 112,
                          fit: BoxFit.cover,
                        ),
                        if (_lens != null) ...[
                          Positioned(
                            top: 6,
                            left: 0,
                            right: 0,
                            child: Text(_lens!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 28)),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              color: AppColors.midnight.withValues(alpha: 0.7),
                              child: const Text('Lens on',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppColors.warmIvory,
                                      fontSize: 10)),
                            ),
                          ),
                        ],
                      ],
                    )
                  : Container(
                      width: 84,
                      height: 112,
                      color: AppColors.midnight,
                      child: const Icon(Icons.videocam_off_outlined,
                          color: AppColors.softRose),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
