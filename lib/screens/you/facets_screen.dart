import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';

class FacetsScreen extends StatefulWidget {
  const FacetsScreen({super.key});
  @override
  State<FacetsScreen> createState() => _FacetsScreenState();
}

class _FacetsScreenState extends State<FacetsScreen> {
  String _facet = 'Public';
  static const _audiences = {
    'everyone': 'Everyone',
    'circles': 'Friends & Inner circle',
    'matches': 'Dating matches',
    'hidden': 'Only me',
  };
  @override
  Widget build(BuildContext context) => GlassScaffold(
        appBar: AppBar(title: const Text('Facets')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'Choose who can see each field in each facet. Changes are saved for this session. Live profile enforcement is not connected yet.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final facet in ['Public', 'Circles', 'Dating', 'Professional'])
              ChoiceChip(
                  label: Text(facet),
                  selected: _facet == facet,
                  onSelected: (_) => setState(() => _facet = facet)),
          ]),
          const SizedBox(height: 12),
          const Text(
              'Dates stays separate: 21+ and ID-verified. Choosing an audience never grants access to Dates.'),
          for (final field in Services.prefs.facetAudience.entries) ...[
            const SizedBox(height: 12),
            GlassContainer(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  Text(field.key,
                      style: Theme.of(context).textTheme.titleMedium),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: field.value[_facet],
                    items: [
                      for (final a in _audiences.entries)
                        DropdownMenuItem(value: a.key, child: Text(a.value))
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => field.value[_facet] = value);
                      }
                    },
                  ),
                ])),
          ],
        ]),
      );
}
