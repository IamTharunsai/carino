import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/member.dart';
import '../../models/message.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import 'conversation_screen.dart';

/// Wave 2 · Video Prompt Reply recorder (CROWD-FEATURES #22).
///
/// A 5–15s private video answer to one of a member's profile prompts.
/// The record flow is a REAL state machine — idle → recording (a live
/// timer ring that stops at exactly 15s) → preview → send — and the
/// sent card carries the real recorded length and the captions state.
///
/// DEMO honesty: this build has no camera pipeline, so the viewfinder
/// is a labelled demo frame. The timer, the 15s cap, the captions
/// toggle and the delivered chat card are all real; the label says
/// exactly which part is the demo.
class VideoReplyScreen extends StatefulWidget {
  const VideoReplyScreen({
    super.key,
    required this.member,
    required this.prompt,
  });

  final Member member;
  final PromptAnswer prompt;

  @override
  State<VideoReplyScreen> createState() => _VideoReplyScreenState();
}

class _VideoReplyScreenState extends State<VideoReplyScreen> {
  /// 15 seconds, in tenths — the design cap for prompt replies.
  static const int _maxTenths = 150;

  Timer? _timer;
  int _tenths = 0;
  bool _recording = false;
  bool _recorded = false;

  /// Captions ON by default (CROWD-FEATURES #22).
  bool _captions = true;

  int get _seconds => (_tenths / 10).ceil().clamp(0, 15);

  String get _clock =>
      '0:${_seconds.toString().padLeft(2, '0')} / 0:15';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecord() {
    if (_recorded) return;
    if (_recording) {
      _stop();
      return;
    }
    setState(() {
      _recording = true;
      _tenths = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _tenths++);
      if (_tenths >= _maxTenths) _stop();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _recording = false;
      _recorded = _tenths > 0;
    });
  }

  void _retake() {
    setState(() {
      _tenths = 0;
      _recorded = false;
    });
  }

  void _send() {
    final member = widget.member;
    final seconds = _seconds < 1 ? 1 : _seconds;
    final conversation = Services.store.conversationFor(member.id);
    Services.store.appendMessage(
      conversation.id,
      ChatMessage(
        id: 'local-vr-${DateTime.now().millisecondsSinceEpoch}',
        text: 'Video reply',
        fromMe: true,
        timeLabel: 'now',
        isVideoReply: true,
        videoReplyPrompt: widget.prompt.question,
        videoReplySeconds: seconds,
        videoReplyCaptions: _captions,
      ),
    );
    if (!mounted) return;
    // Land in the thread so the delivered card is visibly REAL.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(conversation: conversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Video reply')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          // The prompt being answered — theirs, verbatim.
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${member.firstName}\'s prompt',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(widget.prompt.question,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('"${widget.prompt.answer}"',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Viewfinder (demo frame — labelled).
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 3 / 3.4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(AppConfig.assetBackdropMatch,
                      fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x66151014), Color(0xB3151014)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: Chip(
                      avatar: Icon(Icons.videocam_outlined,
                          size: 13, color: AppColors.warmIvory),
                      label: Text('Demo recorder'),
                      backgroundColor: AppColors.midnight,
                      labelStyle: TextStyle(
                          fontSize: 11, color: AppColors.warmIvory),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  if (_recording)
                    const Positioned(
                      top: 14,
                      right: 14,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 11, color: AppColors.sparkCoral),
                          SizedBox(width: 5),
                          Text('REC',
                              style: TextStyle(
                                  color: AppColors.warmIvory,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        _recorded
                            ? 'That\'s a take — review it below, retake, '
                                'or send it to ${member.firstName}.'
                            : _recording
                                ? 'Talking to ${member.firstName}… '
                                    'tap stop when you\'re done.'
                                : 'Your camera view lives here in the live '
                                    'app. Tap record — up to 15 seconds, '
                                    'just you answering the prompt.',
                        style: const TextStyle(
                            color: AppColors.warmIvory, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (_captions && (_recording || _recorded))
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '…your words appear here as captions…',
                          style: TextStyle(
                              color: AppColors.warmIvory,
                              fontSize: 13,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Record control: timer ring + button.
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _tenths / _maxTenths,
                        strokeWidth: 5,
                        color: AppColors.sparkCoral,
                        backgroundColor:
                            AppColors.softRose.withValues(alpha: 0.3),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: _toggleRecord,
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: _recording
                                  ? AppColors.emberCrimson
                                  : AppColors.sparkCoral,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _recording
                                  ? Icons.stop
                                  : Icons.fiber_manual_record,
                              color: AppColors.warmIvory,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(_clock, style: theme.textTheme.titleSmall),
                Text(
                  _recorded
                      ? 'Recorded — ${_seconds}s'
                      : _recording
                          ? 'Recording… the ring is the real 15s cap'
                          : 'Tap to record',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Captions'),
            subtitle: const Text(
                'On by default — replies stay watchable with sound off.'),
            value: _captions,
            onChanged:
                _recording ? null : (v) => setState(() => _captions = v),
          ),
          if (_recorded) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SparkButton(
                    label: 'Retake',
                    secondary: true,
                    icon: Icons.replay_outlined,
                    onPressed: _retake,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SparkButton(
                    label: 'Send reply',
                    icon: Icons.send_outlined,
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.sparkCoral),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Private — only ${member.firstName} sees this reply, '
                  'in your chat. It answers their prompt; it is never '
                  'posted publicly.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
