import 'package:flutter/material.dart';
import '../../models/safety.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_alert.dart';
import '../../widgets/spark_button.dart';

/// Trusted contacts: the people who get your alert (with your location)
/// when you tap "I don't feel safe", and your "home safe" text. They don't
/// need the app.
class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  final _prefs = Services.prefs;
  late final _message = TextEditingController(text: _prefs.alertMessage);

  @override
  void dispose() {
    _prefs.alertMessage = _message.text.trim().isEmpty ? defaultAlertMessage : _message.text.trim();
    _prefs.save();
    _message.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add a trusted contact'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    final n = name.text.trim();
    final p = phone.text.trim();
    if (n.isEmpty || p.replaceAll(RegExp(r'\D'), '').length < 7) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a name and a full phone number.')));
      }
      return;
    }
    setState(() => _prefs.trustedContacts.add((name: n, phone: p)));
    _prefs.save();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Trusted contacts')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Your people', style: t.titleMedium),
        Text('They get your alert and location if you tap “I don’t feel safe”, and a text when you’re home safe.',
            style: t.bodySmall),
        const SizedBox(height: 8),
        for (final c in [..._prefs.trustedContacts])
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(c.name),
            subtitle: Text(c.phone),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove ${c.name}',
              onPressed: () {
                setState(() => _prefs.trustedContacts.remove(c));
                _prefs.save();
              },
            ),
          ),
        SparkButton(label: 'Add a contact', icon: Icons.person_add_alt_outlined, secondary: true, onPressed: _add),
        const SizedBox(height: 20),
        Text('Your alert message', style: t.titleMedium),
        const SizedBox(height: 6),
        TextField(
          controller: _message,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        Text('Your location link is added at the end.', style: t.bodySmall),
        const SizedBox(height: 20),
        SparkButton(label: 'Test the alert', icon: Icons.campaign_outlined, secondary: true, onPressed: () => sendSafetyAlert(context)),
      ]),
    );
  }
}
