import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/safety.dart';
import '../screens/you/trusted_contacts_screen.dart';
import '../services/location.dart';
import '../services/services.dart';

String? deviceCountry() => WidgetsBinding.instance.platformDispatcher.locale.countryCode;

bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<void> _sms(BuildContext context, String body) async {
  final phones = [for (final c in Services.prefs.trustedContacts) c.phone];
  if (phones.isEmpty) {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrustedContactsScreen()));
    return;
  }
  final ok = await launchUrl(smsUri(phones, body, android: _android));
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open messages on this device.")));
  }
}

/// "I don't feel safe": texts every trusted contact your message + where you are.
Future<void> sendSafetyAlert(BuildContext context) async {
  double? lat, lng;
  if (await askLocation()) {
    try {
      final p = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 6));
      lat = double.parse(p.latitude.toStringAsFixed(5));
      lng = double.parse(p.longitude.toStringAsFixed(5));
    } catch (_) {/* send without location rather than not at all */}
  }
  if (!context.mounted) return;
  await _sms(context, alertText(Services.prefs.alertMessage, lat: lat, lng: lng));
}

Future<void> sendHomeSafe(BuildContext context) =>
    _sms(context, "Home safe 💛 Thanks for looking out for me.");

/// Calls the local emergency number after one confirm.
Future<void> callEmergency(BuildContext context) async {
  final n = emergencyNumber(deviceCountry());
  final go = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text('Call $n?'),
      content: const Text('This calls emergency services now.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(d, true), child: Text('Call $n')),
      ],
    ),
  );
  if (go == true) await launchUrl(Uri.parse('tel:$n'));
}

/// The SOS sheet: alert my people, or call emergency services.
Future<void> showSosSheet(BuildContext context) {
  final n = emergencyNumber(deviceCountry());
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (s) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Need help?', style: Theme.of(s).textTheme.titleLarge),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(s);
              sendSafetyAlert(context);
            },
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Alert my trusted contacts'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(s);
              callEmergency(context);
            },
            icon: const Icon(Icons.call),
            label: Text('Call $n'),
          ),
        ]),
      ),
    ),
  );
}
