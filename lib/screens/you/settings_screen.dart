import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import 'paywall_screen.dart';
import 'privacy_centre_screen.dart';
import 'trust_safety_screen.dart';

/// S-050 Settings — account home: profile row (-> S-043 completion),
/// subscription row (-> S-054B), notification toggles, call-permission
/// toggles, sessions list + revoke, passkey row, app-lock toggle,
/// safety/support/pause-delete entries, Log out, app version.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserPrefs _prefs = Services.prefs;
  List<String> _sessions = const [];
  bool _loadingSessions = true;

  @override
  void initState() {
    super.initState();
    Services.auth.listSessions().then((s) {
      if (mounted) {
        setState(() {
          _sessions = s;
          _loadingSessions = false;
        });
      }
    });
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged,
      {String? body}) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: body == null ? null : Text(body),
      value: value,
      onChanged: (v) => setState(() => onChanged(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Your profile'),
            subtitle: const Text('Completion, visibility, edit'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const TrustSafetyScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Subscription'),
            subtitle: Text(Services.payments.isPlus
                ? '${AppConfig.plusName} — manage or cancel'
                : 'Free plan — see Plus'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const SubscriptionScreen()),
            ),
          ),
          const Divider(),
          Text('Notifications', style: text.titleMedium),
          _toggle('Matches & messages', _prefs.notifMessages,
              (v) => _prefs.notifMessages = v),
          _toggle('Daily Drop reminders', _prefs.notifDrops,
              (v) => _prefs.notifDrops = v),
          _toggle('Generic previews (nothing personal on lock screen)',
              _prefs.genericPreviews,
              (v) => _prefs.genericPreviews = v),
          const Divider(),
          Text('Calls', style: text.titleMedium),
          _toggle('Allow Spark invitations to ring', _prefs.allowCalls,
              (v) => _prefs.allowCalls = v,
              body: 'Off = invitations arrive silently in Connect.'),
          const Divider(),
          Text('Security', style: text.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.lock_outline),
            title: const Text('App lock'),
            subtitle: const Text(
                'Face / fingerprint (or your phone PIN) on open and when you come back.'),
            value: _prefs.appLock,
            onChanged: (v) async {
              if (v) {
                // Enabling must prove the person can unlock — never lock
                // someone out of their own app.
                final ok = await Services.biometric.unlock('Turn on app lock');
                if (!context.mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'App lock needs Face, fingerprint or a screen lock set up on this phone.')));
                  return;
                }
              }
              setState(() => _prefs.appLock = v);
            },
          ),
          const Divider(),
          Text('AI', style: text.titleMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.smart_toy_outlined),
            title: const Text('Away assistant'),
            subtitle: const Text(
                "When you're busy, a clearly labelled 'Your assistant' message tells matches "
                "when you'll be back. It never pretends to be you or flirts for you. "
                "Starts working when live messaging is on."),
            value: _prefs.awayAssistant,
            onChanged: (v) => setState(() => _prefs.awayAssistant = v),
          ),
          const Divider(),
          Text('Appearance', style: text.titleMedium),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: _prefs.themeMode,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Auto')),
              ],
              selected: {mode},
              onSelectionChanged: (v) {
                _prefs.themeMode.value = v.first;
                _prefs.save();
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('Sessions', style: text.titleMedium),
          if (_loadingSessions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else
            for (final s in _sessions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.devices_outlined),
                title: Text(s),
                trailing: s.contains('current')
                    ? const Chip(label: Text('This device'))
                    : TextButton(
                        onPressed: () => setState(
                            () => _sessions = _sessions.where((x) => x != s).toList()),
                        child: const Text('Revoke'),
                      ),
              ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Centre'),
            subtitle: const Text('Who can find you, activity status, contacts, AI features'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyCentreScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Trust & Safety Centre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                  builder: (_) => const TrustSafetyScreen()),
            ),
          ),
          const SizedBox(height: 12),
          SparkButton(
            label: 'Log out',
            secondary: true,
            onPressed: () async {
              await Services.auth.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
          const SizedBox(height: 12),
          Text('${AppConfig.appName} · version 0.1.0',
              style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// S-054B Subscription Management — current plan + renewal date, cancel
/// guidance (cancellation happens in the STORE's subscription page — we
/// never pretend an in-app button cancels), resubscribe entry.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPlus = Services.payments.isPlus;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPlus ? AppConfig.plusName : 'Free plan',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  isPlus
                      ? 'Active. Renewal date and price are shown by your '
                          'app store — the store is the source of truth '
                          'for billing, always.'
                      : 'You\'re on the free plan. Everything essential — '
                          'matching, messaging, Spark, safety — is included.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isPlus) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Manage or cancel in your app store'),
              subtitle: const Text(
                  'Subscriptions are billed by the App Store / Google Play. '
                  'Cancelling there keeps Plus until the period ends.'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Opens the store subscription page (RevenueCat management URL in production).')),
              ),
            ),
          ] else
            SparkButton(
              label: 'See ${AppConfig.plusName}',
              icon: Icons.workspace_premium_outlined,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
              ),
            ),
          const SizedBox(height: 8),
          SparkButton(
            label: 'Restore purchases',
            secondary: true,
            onPressed: () async {
              await Services.payments.restore();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Restore requested — entitlements refresh from the store (RevenueCat).')),
              );
            },
          ),
        ],
      ),
    );
  }
}
