import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-014B Permission Primers — one purpose-specific primer at a time,
/// shown AFTER the profile is published and BEFORE the OS prompt (the OS
/// prompt itself fires from the feature that needs it; a primer is never
/// a substitute and never blocks). Both choices are always equal weight:
/// Allow and Not now. Declining never punishes — features explain their
/// limited state where they live (S-059 PermissionDeniedState).
class PermissionPrimersScreen extends StatefulWidget {
  const PermissionPrimersScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<PermissionPrimersScreen> createState() =>
      _PermissionPrimersScreenState();
}

class _Primer {
  const _Primer(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class _PermissionPrimersScreenState extends State<PermissionPrimersScreen> {
  int _index = 0;
  final Map<String, bool> _granted = {};

  static const List<_Primer> _primers = [
    _Primer(
      Icons.notifications_outlined,
      'Notifications',
      'So a match, a message, or a Spark invitation reaches you in time. '
          'Previews stay generic — never names or message text on your '
          'lock screen.',
    ),
    _Primer(
      Icons.photo_camera_outlined,
      'Camera',
      'For your video intro, Spark video sessions, and in-chat photos. '
          'Nothing is captured outside the moments you choose.',
    ),
    _Primer(
      Icons.mic_none_outlined,
      'Microphone',
      'For voice intros, voice notes, and Spark calls. The mic is only '
          'live while you\'re recording or in a call.',
    ),
    _Primer(
      Icons.location_on_outlined,
      'Location',
      'To show distance bands (“~2 mi”) — never your exact location, '
          'never your coordinates shown to anyone. Worldwide discovery '
          'works without it.',
    ),
  ];

  void _answer(bool allow) {
    final primer = _primers[_index];
    _granted[primer.title] = allow;
    // INTEGRATION POINT: on Allow, trigger the real OS permission request
    // for this capability here (permission_handler / platform API). On
    // Not now, record the decline and move on — no re-ask loops.
    if (_index == _primers.length - 1) {
      widget.onDone();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primer = _primers[_index];
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < _primers.length; i++) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        // Filled = COMPLETED primers only (i < _index);
                        // the current one reads as in-progress (coral),
                        // the rest stay faint.
                        color: i < _index
                            ? AppColors.emberCrimson
                            : i == _index
                                ? AppColors.sparkCoral
                                : AppColors.softRose.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(primer.icon, size: 56, color: AppColors.sparkCoral),
                    const SizedBox(height: 16),
                    Text(primer.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(primer.body,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SparkButton(
              label: 'Allow',
              onPressed: () => _answer(true),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Not now',
              secondary: true,
              onPressed: () => _answer(false),
            ),
            TextButton(
              // Skip the whole primer run — declining everything is a
              // legitimate choice, never a punishment path.
              onPressed: widget.onDone,
              child: const Text('Skip all'),
            ),
            const SizedBox(height: 6),
            Text(
              'You can change any of these later in your phone\'s Settings.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
