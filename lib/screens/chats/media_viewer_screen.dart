import 'package:flutter/material.dart';
import '../../widgets/secure_screen.dart';
import '../../models/message.dart';
import '../../theme/app_colors.dart';
import '../../widgets/safety_actions.dart';

/// S-037 Media Viewer — full-screen photo/video from a conversation.
/// View-once media: opening CONSUMES it (server marks it; the sender sees
/// "Opened"). We show exactly what can be true: a consumed view-once shows
/// its placeholder forever after — and the honesty rule still applies:
/// screenshots can't be prevented, only detected + reported.
class MediaViewerScreen extends StatelessWidget {
  const MediaViewerScreen({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final consumed = message.viewOnce && message.mediaConsumed;
    return SecureScreen(child: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report this media',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Use Report from the chat menu — it attaches this media to the case (sealed evidence).'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: consumed || message.mediaAsset == null
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_off_outlined,
                        size: 44, color: AppColors.softRose),
                    const SizedBox(height: 12),
                    Text(
                      consumed
                          ? 'View-once media — already opened. It isn\'t stored or replayable.'
                          : 'Media placeholder (demo asset not attached).',
                      style: const TextStyle(color: AppColors.warmIvory),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Image.asset(message.mediaAsset!, fit: BoxFit.contain),
      ),
      bottomNavigationBar: message.viewOnce
          ? const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Text(
                'View-once: closing marks this opened. Screenshots can\'t '
                'be blocked on any phone — if one is detected, the sender '
                'is told.',
                style: TextStyle(color: AppColors.softRose, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    ));
  }
}

/// Keeps SafetyActions reachable from media surfaces in one import.
typedef MediaSafety = SafetyActions;
