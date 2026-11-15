import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

class TrustGraphScreen extends StatefulWidget {
  const TrustGraphScreen({super.key});
  @override
  State<TrustGraphScreen> createState() => _TrustGraphScreenState();
}

class _TrustGraphScreenState extends State<TrustGraphScreen> {
  final _codeInput = TextEditingController();
  final _note = TextEditingController();
  late String _person = MockData.friends.first.id;
  String _code = _newCode();
  String? _error;
  static String _newCode() =>
      (100000 + Random.secure().nextInt(900000)).toString();
  @override
  void dispose() {
    _codeInput.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassScaffold(
        appBar: AppBar(title: const Text('Trust Graph')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'Demo preview: meeting confirmations and vouches stay on this device for this session. Live confirmation needs both phones and a server-issued one-time code. Meeting someone is not a safety guarantee.'),
          const SizedBox(height: 16),
          GlassContainer(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text('Confirm a meeting',
                    style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String>(
                    isExpanded: true,
                    value: _person,
                    items: [
                      for (final p in MockData.friends)
                        DropdownMenuItem(value: p.id, child: Text(p.name))
                    ],
                    onChanged: (id) {
                      if (id != null) {
                        setState(() {
                          _person = id;
                          _code = _newCode();
                          _codeInput.clear();
                          _error = null;
                        });
                      }
                    }),
                Text('Preview code: $_code'),
                TextField(
                    controller: _codeInput,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                        labelText: 'Matching code', errorText: _error)),
                SparkButton(
                    label: 'Confirm in demo',
                    onPressed: () => setState(() {
                          final success = Services.trust.confirmMeeting(_person,
                              myCode: _code, theirCode: _codeInput.text.trim());
                          _error = success ? null : 'The codes do not match.';
                          if (success) {
                            _code = _newCode();
                            _codeInput.clear();
                          }
                        })),
              ])),
          const SizedBox(height: 16),
          Text('People you have met',
              style: Theme.of(context).textTheme.titleMedium),
          if (Services.trust.met.isEmpty)
            const Text('No confirmed meetings yet.'),
          for (final id in Services.trust.met)
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.handshake_outlined),
                title: Text(MockData.personById(id).name),
                subtitle: Text(Services.prefs.givenVouches[id] ??
                    'No vouch written by you.')),
          const SizedBox(height: 12),
          Text('Vouch for ${MockData.personById(_person).firstName}',
              style: Theme.of(context).textTheme.titleMedium),
          const Text(
              'Write in your own name, only for someone you have met. This preview does not send it.'),
          TextField(
              controller: _note,
              maxLength: 240,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Your experience with them')),
          SparkButton(
              label: 'Save my vouch in demo',
              onPressed: !Services.trust.hasMet(_person)
                  ? null
                  : () {
                      if (_note.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Write a short note first — what makes them trustworthy?')));
                        return;
                      }
                      setState(() {
                        Services.prefs.givenVouches[_person] =
                            _note.text.trim();
                        _note.clear();
                      });
                    }),
          const SizedBox(height: 16),
          Text('Vouches from others',
              style: Theme.of(context).textTheme.titleMedium),
          if (Services.trust.vouches.isEmpty)
            const Text(
                'No vouches received. You cannot write a vouch as someone else.'),
          for (final v in Services.trust.vouches.entries)
            ListTile(
                title: Text(MockData.personById(v.key).name),
                subtitle: Text(v.value)),
        ]),
      );
}
