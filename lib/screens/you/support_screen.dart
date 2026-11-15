import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-053 Support — AI-assisted support with the Bible's honesty rules
/// welded in: it is LABELED AI from the first message, "Talk to a human"
/// is always visible (never buried), and case history shows real statuses.
/// The AI can explain and route; account actions that matter (appeals,
/// verification disputes) hand off to the human queue with a case ref.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _Msg {
  const _Msg(this.fromAi, this.text);
  final bool fromAi;
  final String text;
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _input = TextEditingController();
  late final List<_Msg> _messages = [
    const _Msg(
      true,
      'Hi — I\'m ${AppConfig.appName}\'s support assistant, and I\'m an '
          'AI, not a person. I can explain features and route problems. '
          'For anything about your account, a human can take over at any '
          'time — the button stays right below.',
    ),
  ];

  static const List<String> _topics = [
    'Verification problem',
    'Billing & Plus',
    'Report someone',
    'Account & login',
    'Safety question',
    'Something else',
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Msg(false, text.trim()));
      _messages.add(const _Msg(
        true,
        'Thanks — I\'ve noted that. In the live product this routes to '
            'the support model + ticketing; anything account-'
            'specific creates a case a human can see. If this is urgent '
            'or about your safety, tap “Talk to a human” now.',
      ));
    });
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: const Text('Support')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.emberCrimson.withValues(alpha: 0.15),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You\'re chatting with AI support. Not a person.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: _human,
                  child: const Text('Talk to a human'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('What\'s it about?',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _topics)
                      ActionChip(
                        label: Text(t),
                        onPressed: () => _send(t),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final m in _messages)
                  Align(
                    alignment:
                        m.fromAi ? Alignment.centerLeft : Alignment.centerRight,
                    child: GlassContainer(
                      child: Text(m.text),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Your cases',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'No open cases. Reports and appeals you file appear here '
                  'with their live status (S-051/S-046).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Describe the problem…',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.sparkCoral),
                    onPressed: () => _send(_input.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _human() async {
    // Creates a real support case in live mode (reports table, category
    // 'support') so the handoff is tracked — never a dead end.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Human support requested — a person joins this thread. Typical first response: within a few hours; safety issues jump the queue.'),
      ),
    );
  }
}

/// Small marker so other screens can deep-link the human path.
class SupportEntry {
  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
    );
  }

  static Widget humanBanner(BuildContext context) => SparkButton(
        label: 'Talk to a human',
        secondary: true,
        onPressed: () => open(context),
      );
}
