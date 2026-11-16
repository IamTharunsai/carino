import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../services/services.dart';
import '../../widgets/spark_button.dart';

/// S-008 Intentions Setup — chosen BEFORE discovery, shown on the card.
/// Also reused (via the You tab) as the Intentions editor (S-045).
///
/// Blueprint S-008 options, all present: primary intention (incl. "Still
/// exploring" with a revisit prompt later — never a dead end), relationship
/// structure, pace, availability, and a hard rule: the card NEVER ships
/// without an intention — Continue is disabled until one is picked.
class IntentionsScreen extends StatefulWidget {
  const IntentionsScreen({super.key, required this.onDone, this.initial});

  final ValueChanged<Intention> onDone;
  final Intention? initial;

  @override
  State<IntentionsScreen> createState() => _IntentionsScreenState();
}

class _IntentionsScreenState extends State<IntentionsScreen> {
  Intention? _selected;
  String _structure = Services.prefs.structure;
  String _pace = Services.prefs.pace;
  String _availability = Services.prefs.availability;

  static const List<String> _structures = [
    'Monogamy',
    'Open to ENM',
    'Polyamory',
    'Figuring it out',
  ];
  static const List<String> _paces = [
    'Chat first',
    'Video first',
    'Meet soon',
    'Slow burn',
  ];
  static const List<String> _availabilities = [
    'Tonight',
    'This week',
    'Weekends',
    'Flexible',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  Widget _dimension(String label, List<String> options, String value,
      ValueChanged<String> onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(o),
                selected: value == o,
                selectedColor: AppColors.blush,
                onSelected: (_) => setState(() => onPick(o)),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('What are you here for?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Say it plainly — it\'s printed on your card, and you\'ll mostly '
            'see people who want the same thing. Change it anytime.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          for (final intention in Intention.values) ...[
            GlassContainer(
              opacity: _selected == intention ? 0.85 : null,
              onTap: () => setState(() => _selected = intention),
              child: Row(
                children: [
                  Icon(
                    _selected == intention
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(intention.label,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(intention.tagline,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_selected == Intention.stillExploring)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Totally fine. We\'ll gently check in after a few weeks — '
                'no pressure, no lock-in.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          _dimension('Relationship structure', _structures, _structure,
              (v) => _structure = v),
          _dimension('Pace', _paces, _pace, (v) => _pace = v),
          _dimension('Availability', _availabilities, _availability,
              (v) => _availability = v),
          const SizedBox(height: 24),
          SparkButton(
            label: 'Continue',
            onPressed:
                _selected == null
                    ? null
                    : () {
                        Services.prefs
                          ..intention = _selected!
                          ..structure = _structure
                          ..pace = _pace
                          ..availability = _availability
                          ..save();
                        widget.onDone(_selected!);
                      },
          ),
        ],
      ),
    );
  }
}
