import 'dart:async';
import 'package:flutter/material.dart';
import '../models/member.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'spark_button.dart';

/// Video Reply to a prompt (TikTok "duet" energy, dating-safe):
/// a 5–15s clip sent PRIVATELY to one person as a like with a message.
/// Captions default ON, it is pre-screened before delivery, and it plays
/// tap-to-play with sound off until tapped — never autoplay with sound.
///
/// INTEGRATION POINT: camera capture -> media upload (pre-signed) ->
/// moderation hold -> likes row with anchor_type 'video_reply'. The demo
/// records a timed placeholder so the flow and its rules are real.
Future<bool?> showVideoReplySheet(
  BuildContext context, {
  required Member member,
  required PromptAnswer prompt,
}) {
  return showGlassSheet<bool>(
    context,
    child: _VideoReply(member: member, prompt: prompt),
  );
}

class _VideoReply extends StatefulWidget {
  const _VideoReply({required this.member, required this.prompt});
  final Member member;
  final PromptAnswer prompt;

  @override
  State<_VideoReply> createState() => _VideoReplyState();
}

class _VideoReplyState extends State<_VideoReply> {
  static const int _max = 15;
  static const int _min = 5;
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;
  bool _captions = true;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_recording) {
      _timer?.cancel();
      setState(() => _recording = false);
      return;
    }
    setState(() {
      _seconds = 0;
      _recording = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= _max) {
        t.cancel();
        setState(() => _recording = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ready = !_recording && _seconds >= _min;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Reply with video', style: text.titleLarge),
        const SizedBox(height: 4),
        Text('To ${widget.member.firstName}\'s “${widget.prompt.question}”',
            style: text.bodySmall),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.plumCharcoal),
                Center(
                  child: Icon(
                    _recording ? Icons.fiber_manual_record : Icons.videocam_outlined,
                    size: 56,
                    color: _recording ? AppColors.sparkCoral : AppColors.softRose,
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Chip(
                    label: Text('0:${_seconds.toString().padLeft(2, '0')} / 0:$_max'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (_captions)
                  const Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Text(
                      'Captions on — added automatically, editable before sending.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.warmIvory, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Captions'),
          value: _captions,
          onChanged: (v) => setState(() => _captions = v),
        ),
        SparkButton(
          label: _recording ? 'Stop' : (_seconds > 0 ? 'Record again' : 'Record'),
          icon: _recording ? Icons.stop : Icons.fiber_manual_record,
          secondary: ready,
          onPressed: _toggle,
        ),
        const SizedBox(height: 8),
        SparkButton(
          label: 'Send privately',
          icon: Icons.send_outlined,
          onPressed: ready ? () => Navigator.of(context).pop(true) : null,
        ),
        const SizedBox(height: 6),
        Text(
          'Only ${widget.member.firstName} can see it. It\'s pre-screened '
          'before delivery and never autoplays with sound.',
          style: text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
