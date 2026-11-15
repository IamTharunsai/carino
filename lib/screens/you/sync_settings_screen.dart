import 'package:flutter/material.dart';
import '../../models/sync.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/sync_widgets.dart';

/// You → "How I text & comfort". Your texting style (shown to matches so
/// nobody misreads a slow reply) and comfort rules the app enforces for
/// both of you: calls, photos, first-meet time.
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _prefs = Services.prefs;
  late ReplyPace? _pace = _prefs.myStyle.pace;
  late MsgLength? _length = _prefs.myStyle.length;
  late VoiceNotes? _voice = _prefs.myStyle.voice;
  late Humour? _humour = _prefs.myStyle.humour;
  late final _loves = TextEditingController(text: _prefs.myStyle.loves.join(', '));
  late final _avoid = TextEditingController(text: _prefs.myStyle.avoid.join(', '));
  late bool _noCalls = _prefs.myComfort.noCallsBeforeMeet;
  late int _photoDays = _prefs.myComfort.photosAfterDays;
  late bool _daytime = _prefs.myComfort.daytimeFirstMeet;

  static List<String> _split(String s) => [
        for (final p in s.split(','))
          if (p.trim().isNotEmpty) p.trim().length > 30 ? p.trim().substring(0, 30) : p.trim()
      ].take(5).toList();

  TextingStyle get _style => TextingStyle(
        pace: _pace,
        length: _length,
        voice: _voice,
        humour: _humour,
        loves: _split(_loves.text),
        avoid: _split(_avoid.text),
      );

  ComfortRules get _comfort => ComfortRules(
        noCallsBeforeMeet: _noCalls,
        photosAfterDays: _photoDays,
        daytimeFirstMeet: _daytime,
      );

  @override
  void dispose() {
    _loves.dispose();
    _avoid.dispose();
    super.dispose();
  }

  Widget _pick<T extends Enum>(String title, List<T> values, T? value,
      String Function(T) label, ValueChanged<T?> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in values)
                ChoiceChip(
                  label: Text(label(v)),
                  selected: value == v,
                  // Tap again to clear — unanswered is always allowed.
                  onSelected: (on) => setState(() => onPick(on ? v : null)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    _prefs.myStyle = _style;
    _prefs.myComfort = _comfort;
    await _prefs.save();
    Services.analytics.action('sync_settings_saved');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved. Your matches see this on your profile and in chat.')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('How I text & comfort')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Help matches read you right. Everything is optional — skip what '
            'you like, change it any time.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 14),
          _pick('Reply pace', ReplyPace.values, _pace, (v) => v.label, (v) => _pace = v),
          _pick('Message length', MsgLength.values, _length, (v) => v.label, (v) => _length = v),
          _pick('Voice notes', VoiceNotes.values, _voice, (v) => v.label, (v) => _voice = v),
          _pick('Humour', Humour.values, _humour, (v) => v.label, (v) => _humour = v),
          TextField(
            controller: _loves,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Topics I love',
              helperText: 'Comma-separated, up to 5',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _avoid,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Please don\'t ask about',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          Text('Comfort rules', style: text.titleMedium),
          Text('Cariño enforces these in chat and plans — for both of you, until you\'ve met.',
              style: text.bodySmall),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('No calls before we\'ve met'),
            value: _noCalls,
            onChanged: (v) => setState(() => _noCalls = v),
          ),
          Text('Photos from matches', style: text.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final d in const [0, 3, 7])
                ChoiceChip(
                  label: Text(d == 0 ? 'Any time' : 'After $d days'),
                  selected: _photoDays == d,
                  onSelected: (_) => setState(() => _photoDays = d),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('First meet in the daytime'),
            subtitle: const Text('Plans between 08:00 and 18:00 until you\'ve met.'),
            value: _daytime,
            onChanged: (v) => setState(() => _daytime = v),
          ),
          const SizedBox(height: 12),
          Text('This is what matches see', style: text.titleSmall),
          const SizedBox(height: 6),
          TextingCard(title: 'How you text', style: _style, comfort: _comfort),
          const SizedBox(height: 16),
          SparkButton(label: 'Save', onPressed: _save),
        ],
      ),
    );
  }
}
