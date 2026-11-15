import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-055 Pause & Delete — a pushed flow, never a sheet (deliberate
/// friction per NAV & IA). Steps: (1) what happens, export-first offer;
/// (2) pause as the reversible alternative; (3) stepped confirmation —
/// a checkbox understanding + the final button. Deletion removes the
/// profile everywhere immediately; sealed safety records persist ONLY
/// as long as the law requires, then are erased — stated plainly.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _understand = false;
  bool _exported = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Pause or delete')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('We\'re sorry to see you go.', style: text.headlineMedium),
          const SizedBox(height: 10),
          Text(
            'Deleting removes your profile, matches, and chats from other '
            'people\'s apps right away. Sealed safety records are kept '
            'only as long as the law requires, then erased. This cannot '
            'be undone.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Step 1 · Take your data with you',
                    style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Export your profile, settings, and messages first — '
                  'once the account is gone, so is the export.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 10),
                SparkButton(
                  label: _exported
                      ? 'Export done ✓'
                      : 'Download my data first',
                  secondary: true,
                  icon: Icons.download_outlined,
                  onPressed: _exported
                      ? null
                      : () async {
                          final data = await Services.backend.exportMyData();
                          if (!mounted) return;
                          if (data != null) {
                            await Clipboard.setData(ClipboardData(text: data));
                          }
                          if (!mounted) return;
                          setState(() => _exported = true);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(data == null
                                  ? 'This demo has no account data on our servers to export.'
                                  : 'Your data is copied — paste it into a file before deleting.')));
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Or just pause', style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Paused hides you from discovery completely. Your matches '
                  'keep their chats, and you can come back whenever.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 10),
                SparkButton(
                  label: 'Pause my account instead',
                  secondary: true,
                  onPressed: () {
                    Services.prefs.visibility = 'Paused';
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Paused — you\'re off discovery. Welcome back anytime.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Step 2 · Confirm deletion', style: text.titleMedium),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _understand,
            onChanged: (v) => setState(() => _understand = v ?? false),
            title: Text(
              'I understand my profile, matches and chats will be removed '
              'and this can\'t be undone.',
              style: text.bodyMedium,
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB81735),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _understand
                ? () async {
                    // PRODUCTION: BackendService deletion job + revoke all
                    // sessions + sign out (the RootFlow gate then drops to
                    // Welcome). Scaffold: sign out of the demo session.
                    try {
                      await Services.auth.deleteAccount();
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "Couldn't delete your account. Nothing was removed — try again.")));
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                : null,
            child: const Text('Delete my account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep my account'),
          ),
          Text(
            '${AppConfig.appName} never charges to delete, never hides '
            'this flow, and never asks "are you sure?" more than this once.',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
