import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_card.dart';

/// Copies [text]. Returns true only when the copy really happened; on
/// failure it shows the text so the member can select it themselves —
/// never a "Copied" message for something that wasn't copied.
Future<bool> copyText(BuildContext context, String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } catch (_) {
    if (context.mounted) {
      await showGlassSheet<void>(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Couldn't copy automatically", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(text),
            const SizedBox(height: 8),
            Text('Press and hold the text above to copy it.', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }
    return false;
  }
}
