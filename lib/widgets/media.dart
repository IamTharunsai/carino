import 'dart:async';
import 'dart:io' show Directory, File;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';

/// Media is stored as a path; videos carry a `video:` prefix (web paths are
/// blob URLs with no extension, so the prefix is the only reliable flag).
bool isVideo(String item) => item.startsWith('video:');
String mediaPath(String item) => isVideo(item) ? item.substring(6) : item;

final _picker = ImagePicker();

/// Photo or video from the gallery. The OS asks for access the first time.
Future<String?> pickMedia() async {
  final f = await _picker.pickMedia();
  if (f == null) return null;
  final video = (f.mimeType ?? '').startsWith('video') ||
      RegExp(r'\.(mp4|mov|m4v|webm|3gp)$', caseSensitive: false).hasMatch(f.name);
  return video ? 'video:${f.path}' : f.path;
}

Future<String?> takePhoto() async => (await _picker.pickImage(source: ImageSource.camera))?.path;

Future<String?> recordVideo({int seconds = 30}) async {
  final f = await _picker.pickVideo(
      source: ImageSource.camera, maxDuration: Duration(seconds: seconds));
  return f == null ? null : 'video:${f.path}';
}

/// Camera / gallery / video sheet. Returns the chosen item or null.
Future<String?> chooseMedia(BuildContext context) async {
  final how = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (s) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('From your gallery'),
            onTap: () => Navigator.pop(s, 'gallery')),
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'),
            onTap: () => Navigator.pop(s, 'photo')),
        ListTile(leading: const Icon(Icons.videocam_outlined), title: const Text('Record a video'),
            onTap: () => Navigator.pop(s, 'video')),
      ]),
    ),
  );
  return switch (how) {
    'gallery' => pickMedia(),
    'photo' => takePhoto(),
    'video' => recordVideo(),
    _ => null,
  };
}

/// Shows an asset, a web blob or a file — whichever the path is.
class MediaImage extends StatelessWidget {
  const MediaImage(this.path, {super.key, this.fit = BoxFit.cover});
  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final error = (BuildContext _, Object __, StackTrace? ___) =>
        Container(color: AppColors.emberCrimson.withValues(alpha: 0.15), child: const Icon(Icons.image_outlined));
    if (path.startsWith('assets/')) return Image.asset(path, fit: fit, errorBuilder: error);
    if (kIsWeb || path.startsWith('http')) return Image.network(path, fit: fit, errorBuilder: error);
    return Image.file(File(path), fit: fit, errorBuilder: error);
  }
}

/// A grid tile for a photo or a video (video shows a play badge).
class MediaTile extends StatelessWidget {
  const MediaTile(this.item, {super.key});
  final String item;

  @override
  Widget build(BuildContext context) {
    if (!isVideo(item)) return MediaImage(item);
    return Container(
      color: AppColors.midnight,
      child: const Center(child: Icon(Icons.play_circle_fill, size: 40, color: AppColors.warmIvory)),
    );
  }
}

/// Tap-to-play video (profile intro, posts, previews).
class VideoClip extends StatefulWidget {
  const VideoClip(this.item, {super.key});
  final String item;

  @override
  State<VideoClip> createState() => _VideoClipState();
}

class _VideoClipState extends State<VideoClip> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    final p = mediaPath(widget.item);
    final c = p.startsWith('assets/')
        ? VideoPlayerController.asset(p)
        : (kIsWeb || p.startsWith('http'))
            ? VideoPlayerController.networkUrl(Uri.parse(p))
            : VideoPlayerController.file(File(p));
    _c = c;
    c.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(aspectRatio: 9 / 16, child: Center(child: CircularProgressIndicator()));
    }
    return GestureDetector(
      onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: Stack(alignment: Alignment.center, children: [
          VideoPlayer(c),
          if (!c.value.isPlaying)
            const Icon(Icons.play_circle_fill, size: 56, color: AppColors.warmIvory),
        ]),
      ),
    );
  }
}

/// Voice intro: record (max 30s), listen, retake, delete.
class VoiceRecorderCard extends StatefulWidget {
  const VoiceRecorderCard({super.key, required this.path, required this.onChanged, this.maxSeconds = 30});
  final String? path;
  final ValueChanged<String?> onChanged;
  final int maxSeconds;

  @override
  State<VoiceRecorderCard> createState() => _VoiceRecorderCardState();
}

class _VoiceRecorderCardState extends State<VoiceRecorderCard> {
  final _rec = AudioRecorder();
  final _player = AudioPlayer();
  Timer? _tick;
  int _seconds = 0;
  bool _recording = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _rec.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _rec.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Allow the microphone in your phone settings to record.')));
      }
      return;
    }
    final file = kIsWeb ? '' : '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(const RecordConfig(), path: file);
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= widget.maxSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    _tick?.cancel();
    final path = await _rec.stop();
    setState(() => _recording = false);
    widget.onChanged(path);
  }

  Future<void> _play() async {
    final p = widget.path!;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.play(kIsWeb || p.startsWith('http') ? UrlSource(p) : DeviceFileSource(p));
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_recording) {
      return Row(children: [
        const Icon(Icons.fiber_manual_record, color: AppColors.emberCrimson),
        const SizedBox(width: 8),
        Expanded(child: Text('Recording… 0:${_seconds.toString().padLeft(2, '0')} / 0:${widget.maxSeconds}', style: t.bodyMedium)),
        FilledButton.icon(onPressed: _stop, icon: const Icon(Icons.stop), label: const Text('Stop')),
      ]);
    }
    if (widget.path == null) {
      return Row(children: [
        Expanded(child: Text('Up to ${widget.maxSeconds} seconds. Let them hear your laugh.', style: t.bodyMedium)),
        FilledButton.icon(onPressed: _start, icon: const Icon(Icons.mic), label: const Text('Record')),
      ]);
    }
    return Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
      OutlinedButton.icon(
          onPressed: _play,
          icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
          label: Text(_playing ? 'Stop' : 'Listen')),
      OutlinedButton.icon(onPressed: _start, icon: const Icon(Icons.refresh), label: const Text('Retake')),
      TextButton.icon(
          onPressed: () => widget.onChanged(null),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete')),
    ]);
  }
}
