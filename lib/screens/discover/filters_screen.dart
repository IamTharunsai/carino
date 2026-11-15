import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../you/paywall_screen.dart';

/// Filter configuration (S-017). Filters are RECIPROCAL (blueprint rule):
/// you only see people whose filters include you — the server enforces it;
/// this object is what the client sends.
class FiltersConfig {
  const FiltersConfig({
    this.intention,
    this.ageMin = 21,
    this.ageMax = 45,
    this.maxDistanceMi = 25,
    this.language,
    this.verifiedOnly = true,
    this.exactIntention = false,
    this.worldwideDistance = false,
  });

  final Intention? intention;
  final int ageMin;
  final int ageMax;
  final int maxDistanceMi;
  final String? language;
  final bool verifiedOnly;

  /// Plus: only members whose intention matches the current user's own
  /// intention exactly (Discover honours this in its deck filter).
  final bool exactIntention;

  /// Plus: relaxes the max-distance cap entirely (Discover honours this
  /// in its deck filter).
  final bool worldwideDistance;

  bool get isDefault =>
      intention == null &&
      ageMin == 21 &&
      ageMax == 45 &&
      maxDistanceMi == 25 &&
      language == null &&
      verifiedOnly &&
      !exactIntention &&
      !worldwideDistance;
}

/// S-017 Filters — the full screen the lite sheet grows into:
/// intention, age range, distance, languages, verified-only, Plus-locked
/// rows (advanced: intention-exact, wider distance) that route to the
/// paywall honestly, a too-narrow warning with a one-tap Widen, and
/// Apply / Reset. Nothing here is pre-ticked to shrink anyone's pool
/// silently — the counts stay truthful (S-015/S-016 honesty rules).
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, required this.initial});

  final FiltersConfig initial;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late Intention? _intention = widget.initial.intention;
  late RangeValues _ages =
      RangeValues(widget.initial.ageMin.toDouble(), widget.initial.ageMax.toDouble());
  late double _distance = widget.initial.maxDistanceMi.toDouble();
  late String? _language = widget.initial.language;
  late bool _verifiedOnly = widget.initial.verifiedOnly;
  late bool _exactIntention = widget.initial.exactIntention;
  late bool _worldwideDistance = widget.initial.worldwideDistance;

  static const List<String> _languages = [
    'Any',
    'English',
    'Spanish',
    'Hindi',
    'Telugu',
    'French',
    'Portuguese',
  ];

  bool get _tooNarrow =>
      (_ages.end - _ages.start) < 5 || _distance < 3;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _intention = null;
              _ages = const RangeValues(21, 45);
              _distance = 25;
              _language = null;
              _verifiedOnly = true;
              _exactIntention = false;
              _worldwideDistance = false;
            }),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Filters are reciprocal — you only see people whose filters '
            'include you, too.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Here for', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Everyone'),
                selected: _intention == null,
                selectedColor: AppColors.emberCrimson,
                onSelected: (_) => setState(() => _intention = null),
              ),
              for (final i in Intention.values)
                ChoiceChip(
                  label: Text(i.label),
                  selected: _intention == i,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setState(() => _intention = i),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
              'Age · ${_ages.start.round()}–${_ages.end.round()}',
              style: text.titleMedium),
          RangeSlider(
            values: _ages,
            min: 21,
            max: 65,
            divisions: 44,
            activeColor: AppColors.emberCrimson,
            labels: RangeLabels('${_ages.start.round()}', '${_ages.end.round()}'),
            onChanged: (v) => setState(() => _ages = v),
          ),
          Text('Distance · up to ${_distance.round()} mi',
              style: text.titleMedium),
          Slider(
            value: _distance,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: AppColors.emberCrimson,
            label: '${_distance.round()} mi',
            onChanged: (v) => setState(() => _distance = v),
          ),
          Text('Language', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in _languages)
                ChoiceChip(
                  label: Text(l),
                  selected: (_language ?? 'Any') == l,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) =>
                      setState(() => _language = l == 'Any' ? null : l),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Verified only'),
            subtitle: const Text(
                'Everyone on ${AppConfig.appName} is verified — this stays on for safety.'),
            value: _verifiedOnly,
            // Deliberately locked ON: verification is the floor, not a
            // preference (Bible safety rules).
            onChanged: null,
          ),
          const Divider(),
          Text('Plus filters', style: text.titleMedium),
          if (Services.payments.isPlus) ...[
            // Plus members get REAL toggles, persisted into FiltersConfig
            // on Apply and honoured by Discover's deck filter.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Exact-intention matching'),
              subtitle: const Text(
                  'Only people whose intention matches yours, exactly.'),
              value: _exactIntention,
              activeThumbColor: AppColors.emberCrimson,
              onChanged: (v) => setState(() => _exactIntention = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Worldwide distance'),
              subtitle: const Text('Remove the distance cap entirely.'),
              value: _worldwideDistance,
              activeThumbColor: AppColors.emberCrimson,
              onChanged: (v) => setState(() => _worldwideDistance = v),
            ),
            Text(
              'Demo note: these apply to Discover and the Daily Drop the '
              'moment you tap Apply — no server round-trip in the demo.',
              style: text.bodySmall,
            ),
          ] else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: const Text('Exact-intention matching'),
              subtitle: const Text('Only people whose intention matches yours, exactly.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _plusGate(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: const Text('Worldwide distance'),
              subtitle: const Text('Remove the distance cap entirely.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _plusGate(context),
            ),
          ],
          if (_tooNarrow) ...[
            const SizedBox(height: 10),
            GlassContainer(
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: AppColors.sparkCoral),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'That\'s a very small pool — you may see few people. '
                      'Widening even a little helps a lot.',
                      style: text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Widen a little',
              secondary: true,
              onPressed: () => setState(() {
                _ages = const RangeValues(21, 50);
                _distance = 25;
              }),
            ),
          ],
          const SizedBox(height: 20),
          SparkButton(
            label: 'Apply filters',
            onPressed: () => Navigator.of(context).pop(
              FiltersConfig(
                intention: _intention,
                ageMin: _ages.start.round(),
                ageMax: _ages.end.round(),
                maxDistanceMi: _distance.round(),
                language: _language,
                verifiedOnly: _verifiedOnly,
                exactIntention: _exactIntention,
                worldwideDistance: _worldwideDistance,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _plusGate(BuildContext context) {
    if (Services.payments.isPlus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plus filter enabled (demo).')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
    );
  }
}
