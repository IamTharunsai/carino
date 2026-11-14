import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

class WorkFacetScreen extends StatefulWidget {
  const WorkFacetScreen({super.key});
  @override
  State<WorkFacetScreen> createState() => _WorkFacetScreenState();
}

class _WorkFacetScreenState extends State<WorkFacetScreen> {
  final _form = GlobalKey<FormState>();
  final _role = TextEditingController(text: Services.prefs.workRole);
  final _building = TextEditingController(text: Services.prefs.workBuilding);
  final _openTo = {...Services.prefs.workOpenTo};
  @override
  void dispose() {
    _role.dispose();
    _building.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassScaffold(
        appBar: AppBar(title: const Text('Work facet')),
        body: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Your professional introduction for coffee chats and collaborations. Saved for this session; separate from Dates.'),
              const SizedBox(height: 16),
              GlassContainer(
                  child: Column(children: [
                TextFormField(
                    controller: _role,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: 'Role'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Add your role.'
                        : null),
                TextFormField(
                    controller: _building,
                    maxLength: 200,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'What are you building or exploring?')),
              ])),
              const SizedBox(height: 16),
              Text('Open to', style: Theme.of(context).textTheme.titleMedium),
              Wrap(spacing: 8, children: [
                for (final entry in const {
                  'coffee': 'Coffee',
                  'collabs': 'Collaborations',
                  'mentoring': 'Mentoring',
                  'hiring': 'Hiring'
                }.entries)
                  FilterChip(
                      label: Text(entry.value),
                      selected: _openTo.contains(entry.key),
                      onSelected: (v) => setState(() {
                            if (v) {
                              _openTo.add(entry.key);
                            } else {
                              _openTo.remove(entry.key);
                            }
                          })),
              ]),
              const SizedBox(height: 16),
              SparkButton(
                  label: 'Save work facet',
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    Services.prefs
                      ..workRole = _role.text.trim()
                      ..workBuilding = _building.text.trim()
                      ..workOpenTo = {..._openTo};
                    Navigator.of(context).pop();
                  }),
            ])),
      );
}
