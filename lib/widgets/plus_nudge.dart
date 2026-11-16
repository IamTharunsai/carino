import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../screens/you/paywall_screen.dart';
import 'spark_button.dart';

/// The one upgrade prompt, shown only at a moment of desire (out of likes,
/// wanting to rewind, travel, more Super Likes). Always dismissible, never
/// on first launch, never mid-conversation.
Future<void> showPlusNudge(BuildContext context,
    {required String title, required String body, Widget? extra}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(sheet).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (extra != null) ...[extra, const SizedBox(height: 8)],
            SparkButton(
              label: 'See ${AppConfig.plusName}',
              icon: Icons.workspace_premium_outlined,
              onPressed: () {
                Navigator.of(sheet).pop();
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const PaywallScreen()));
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(sheet).pop(),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    ),
  );
}
