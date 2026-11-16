import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/mock_data.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import 'delete_account_screen.dart';

/// S-047 Privacy Centre — a full screen, not a sheet: visibility control,
/// distance-band display, blocked list WITH unblock, per-feature AI
/// consent toggles, data download, and the delete entry. Everything here
/// writes to [UserPrefs] (server-persisted in production) — the same
/// store S-009 seeded at onboarding, so the two never disagree.
class PrivacyCentreScreen extends StatefulWidget {
  const PrivacyCentreScreen({super.key});

  @override
  State<PrivacyCentreScreen> createState() => _PrivacyCentreScreenState();
}

class _PrivacyCentreScreenState extends State<PrivacyCentreScreen> {
  final UserPrefs _prefs = Services.prefs;

  Widget _toggle(String title, String body, bool value, ValueChanged<bool> f) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(body),
      value: value,
      onChanged: (v) => setState(() => f(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Privacy Centre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Discovery visibility', style: text.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _prefs.visibility,
            onChanged: (v) =>
                setState(() => _prefs.visibility = v ?? 'Discovery'),
            child: const Column(
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Discovery'),
                  subtitle: Text('People nearby can find you.'),
                  value: 'Discovery',
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Incognito'),
                  subtitle: Text('Only people you heart first can see you.'),
                  value: 'Incognito',
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Paused'),
                  subtitle: Text(
                      'Off the map entirely — matches keep their chats.'),
                  value: 'Paused',
                ),
              ],
            ),
          ),
          const Divider(),
          _toggle('Show my activity status',
              'Off = nobody sees when you were last active.',
              _prefs.showActivity, (v) => _prefs.showActivity = v),
          _toggle('Show distance band',
              'Bands like “~2 mi”. Exact location is never shown, either way.',
              _prefs.showDistanceBand, (v) => _prefs.showDistanceBand = v),
          _toggle('Generic notification previews',
              'Lock screen shows “new message” — never names or content.',
              _prefs.genericPreviews, (v) => _prefs.genericPreviews = v),
          _toggle('Exclude my contacts',
              'Never show you to people in your contacts. Starts when contact matching launches — nothing is read today.',
              _prefs.excludeContacts, (v) => _prefs.excludeContacts = v),
          const Divider(),
          Text('AI features — your call, per feature', style: text.titleMedium),
          _toggle('Conversation assistant',
              'Draft openers + replies. Drafts only — you always send.',
              _prefs.aiConversationAssistant,
              (v) => _prefs.aiConversationAssistant = v),
          _toggle('Profile coach',
              'Profile suggestions in Edit Profile.',
              _prefs.aiProfileCoach, (v) => _prefs.aiProfileCoach = v),
          _toggle('Icebreakers',
              'Starter suggestions on new matches.',
              _prefs.aiIcebreakers, (v) => _prefs.aiIcebreakers = v),
          const Divider(),
          Text('Blocked people', style: text.titleMedium),
          const SizedBox(height: 6),
          if (_prefs.blocked.isEmpty)
            Text('Nobody is blocked.', style: text.bodyMedium),
          for (final id in _prefs.blocked.toList())
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage:
                    AssetImage(MockData.memberById(id).photoAsset),
              ),
              title: Text(MockData.memberById(id).name),
              subtitle: const Text('Blocked · hidden both ways'),
              trailing: TextButton(
                onPressed: () async {
                  await Services.backend.removeBlock(id);
                  if (mounted) setState(() {});
                },
                child: const Text('Unblock'),
              ),
            ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download my data'),
            subtitle: const Text(
                'Everything you gave us — profile, settings, messages, plans — as one file.'),
            onTap: () async {
              final data = await Services.backend.exportMyData();
              if (!context.mounted) return;
              if (data == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('This demo has no account data on our servers to export.')));
                return;
              }
              await Clipboard.setData(ClipboardData(text: data));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Your data (${(data.length / 1024).ceil()} KB) is copied — paste it into a file to keep it.')));
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline,
                color: Color(0xFFB81735)),
            title: const Text('Delete account'),
            subtitle: const Text('Export first is offered there too.'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DeleteAccountScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
