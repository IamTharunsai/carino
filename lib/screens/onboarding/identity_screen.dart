import 'package:flutter/material.dart';
import '../../models/experience.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-008A About You — identity, pronouns, orientation and "I want to meet".
/// Also reused from the You tab as the identity editor.
///
/// Inclusion rules:
///  - Every field is optional except "I want to meet" defaulting to everyone.
///  - Each field has its own visibility (everyone / matches / just me).
///    "Just me" fields still power matching but are never shown.
///  - Self-describe is always available; nobody is forced into a list.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final _prefs = Services.prefs;
  late final Set<String> _gender = {..._prefs.gender};
  late String _pronouns = _prefs.pronouns;
  late String _orientation = _prefs.orientation;
  late final Set<String> _want = {..._prefs.wantToMeet};
  late final Map<String, String> _vis = {..._prefs.identityVisibility};
  late final TextEditingController _selfDescribe = TextEditingController(
      text: _prefs.gender.where((g) => !genderOptions.contains(g)).join(', '));
  late final TextEditingController _access =
      TextEditingController(text: _prefs.accessNote);

  @override
  void dispose() {
    _selfDescribe.dispose();
    _access.dispose();
    super.dispose();
  }

  void _save() {
    final custom = _selfDescribe.text.trim();
    _prefs
      ..gender = [..._gender, if (custom.isNotEmpty) custom]
      ..pronouns = _pronouns
      ..orientation = _orientation
      ..wantToMeet = _want.toList()
      ..identityVisibility = _vis
      ..accessNote = _access.text.trim();
    widget.onDone();
  }

  Widget _visibility(String field) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who can see this', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          SegmentedButton<String>(
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment(value: 'everyone', label: Text('Everyone')),
          ButtonSegment(value: 'matches', label: Text('Matches')),
          ButtonSegment(value: 'hidden', label: Text('Only me')),
        ],
        selected: {_vis[field] ?? 'everyone'},
        onSelectionChanged: (v) => setState(() => _vis[field] = v.first),
      ),
        ],
      ),
    );
  }

  Widget _section(String title, String hint, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _chips(List<String> options, bool Function(String) selected,
      void Function(String) toggle) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          FilterChip(
            label: Text(o),
            selected: selected(o),
            selectedColor: AppColors.emberCrimson,
            showCheckmark: false,
            onSelected: (_) => setState(() => toggle(o)),
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
          Text('About you', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Share as much or as little as you like. You choose who sees '
            'each answer, and you can change it anytime.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _section('Gender', 'Pick any that fit, or describe it yourself.', [
            _chips(genderOptions, _gender.contains,
                (o) => _gender.contains(o) ? _gender.remove(o) : _gender.add(o)),
            const SizedBox(height: 10),
            TextField(
              key: const Key('identity-self-describe'),
              controller: _selfDescribe,
              decoration: const InputDecoration(
                labelText: 'Self-describe (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
              ),
            ),
            _visibility('gender'),
          ]),
          _section('Pronouns', 'Shown next to your name.', [
            _chips(pronounOptions, (o) => _pronouns == o,
                (o) => _pronouns = _pronouns == o ? '' : o),
            _visibility('pronouns'),
          ]),
          _section('Orientation', 'Optional. Many people keep this to matches.', [
            _chips(orientationOptions, (o) => _orientation == o,
                (o) => _orientation = _orientation == o ? '' : o),
            _visibility('orientation'),
          ]),
          _section(
            'I want to meet',
            'Used for matching only — never shown. Leave empty to meet everyone. '
                'Discover only shows people who also want to meet you.',
            [
              _chips(wantToMeetOptions, _want.contains,
                  (o) => _want.contains(o) ? _want.remove(o) : _want.add(o)),
            ],
          ),
          _section(
            'Access needs',
            'Optional. Helps plans work for you — e.g. step-free venues, '
                'quiet places, captions on calls.',
            [
              TextField(
                key: const Key('identity-access'),
                controller: _access,
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText: 'Step-free venues, please',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SparkButton(label: 'Continue', onPressed: _save),
          TextButton(
            onPressed: widget.onDone,
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }
}
