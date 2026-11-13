import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-009 Privacy, Contacts & Notifications Setup — an onboarding STEP, not
/// buried settings (blueprint rule). Privacy-first defaults, pre-selected:
/// Discovery visibility, activity hidden, generic notification previews,
/// contact exclusion ON. Every control writes to [UserPrefs] and (live
/// mode) the member's privacy row — never silently changed later.
class PrivacySetupScreen extends StatefulWidget {
  const PrivacySetupScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<PrivacySetupScreen> createState() => _PrivacySetupScreenState();
}

class _PrivacySetupScreenState extends State<PrivacySetupScreen> {
  final UserPrefs _prefs = Services.prefs;

  Widget _toggle({
    required String title,
    required String body,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(body, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      activeThumbColor: AppColors.emberCrimson,
      onChanged: (v) => setState(() => onChanged(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('Your privacy, set before anyone sees you.',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'These start at the most private settings. Loosen any of them '
            'later in Settings — we\'ll never loosen them for you.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Who can find you',
                    style: Theme.of(context).textTheme.titleMedium),
                RadioGroup<String>(
                  groupValue: _prefs.visibility,
                  onChanged: (v) =>
                      setState(() => _prefs.visibility = v ?? 'Discovery'),
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Discovery'),
                        subtitle: Text(
                            'People nearby can see your public profile.'),
                        value: 'Discovery',
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Incognito'),
                        subtitle: Text(
                            'Only people you like first can see you.'),
                        value: 'Incognito',
                      ),
                    ],
                  ),
                ),
                _toggle(
                  title: 'Hide my contacts',
                  body:
                      'We hash your contacts on-device and never show you to people in them. Contacts are never uploaded in plain form.',
                  value: _prefs.excludeContacts,
                  onChanged: (v) => _prefs.excludeContacts = v,
                ),
                _toggle(
                  title: 'Show my activity status',
                  body: 'Off means nobody sees when you were last active.',
                  value: _prefs.showActivity,
                  onChanged: (v) => _prefs.showActivity = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications',
                    style: Theme.of(context).textTheme.titleMedium),
                _toggle(
                  title: 'Generic previews',
                  body:
                      'Lock-screen notifications say “You have a new message” — never names or content.',
                  value: _prefs.genericPreviews,
                  onChanged: (v) => _prefs.genericPreviews = v,
                ),
                _toggle(
                  title: 'Matches & messages',
                  body: 'New matches, messages and plan updates.',
                  value: _prefs.notifMessages,
                  onChanged: (v) => _prefs.notifMessages = v,
                ),
                _toggle(
                  title: 'Spark calls',
                  body: 'Incoming Spark invitations ring like a call.',
                  value: _prefs.allowCalls,
                  onChanged: (v) => _prefs.allowCalls = v,
                ),
                _toggle(
                  title: 'Daily Drop reminders',
                  body: 'One nudge when today\'s drop lands. Never more.',
                  value: _prefs.notifDrops,
                  onChanged: (v) => _prefs.notifDrops = v,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SparkButton(label: 'Looks right — continue', onPressed: widget.onDone),
        ],
      ),
    );
  }
}
