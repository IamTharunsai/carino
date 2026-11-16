import 'package:flutter/material.dart';
import '../../models/coach.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Chat with the AI coach: it asks about what's missing, then writes your
/// bio, interests and a prompt answer. You review — "Use this" fills the
/// form; nothing is saved until you tap Save on your profile.
class ProfileCoachScreen extends StatefulWidget {
  const ProfileCoachScreen({
    super.key,
    required this.hasBio,
    required this.interestCount,
    required this.promptCount,
  });
  final bool hasBio;
  final int interestCount;
  final int promptCount;

  @override
  State<ProfileCoachScreen> createState() => _ProfileCoachScreenState();
}

class _ProfileCoachScreenState extends State<ProfileCoachScreen> {
  late final List<CoachQuestion> _qs = () {
    final q = coachQuestions(
        hasBio: widget.hasBio, interestCount: widget.interestCount, promptCount: widget.promptCount);
    // Profile already full? Offer a fresh bio anyway.
    return q.isEmpty
        ? coachQuestions(hasBio: false, interestCount: 0, promptCount: 0)
        : q;
  }();
  final Map<CoachField, String> _answers = {};
  final _input = TextEditingController();
  CoachDraft? _draft;
  bool _thinking = false;

  int get _step => _answers.length;

  Future<void> _send() async {
    final a = _input.text.trim();
    if (a.isEmpty) return;
    setState(() {
      _answers[_qs[_step].field] = a;
      _input.clear();
    });
    if (_step < _qs.length) return;
    setState(() => _thinking = true);
    final live = await Services.ai.coachDraft([
      for (final q in _qs) (q: q.ask, a: _answers[q.field] ?? ''),
    ]);
    final offline = draftFromAnswers(_answers);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _draft = live == null
          ? offline
          : CoachDraft(
              bio: live.bio ?? offline.bio,
              interests: live.interests.isEmpty ? offline.interests : live.interests,
              promptAnswers: live.firstPlan == null
                  ? offline.promptAnswers
                  : {'My ideal first plan is…': live.firstPlan!},
            );
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Widget _bubble(String text, {required bool me}) => Align(
        alignment: me ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: me ? AppColors.emberCrimson : AppColors.emberCrimson.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(text, style: TextStyle(color: me ? AppColors.warmIvory : null)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = _draft;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Your AI coach')),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (var i = 0; i < _qs.length && i <= _step; i++) ...[
              _bubble(_qs[i].ask, me: false),
              if (_answers[_qs[i].field] case final a?) _bubble(a, me: true),
            ],
            if (_thinking) _bubble('Writing your profile… ✍️', me: false),
            if (d != null) ...[
              _bubble('Here’s you, on a good day 😉 Change anything you like after.', me: false),
              GlassContainer(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (d.bio != null) ...[Text('Bio', style: t.titleSmall), Text(d.bio!), const SizedBox(height: 8)],
                  if (d.interests.isNotEmpty) ...[
                    Text('Interests', style: t.titleSmall),
                    Text(d.interests.join(' · ')),
                    const SizedBox(height: 8),
                  ],
                  for (final e in d.promptAnswers.entries) ...[Text(e.key, style: t.titleSmall), Text(e.value)],
                ]),
              ),
              const SizedBox(height: 12),
              SparkButton(label: 'Use this', icon: Icons.check, onPressed: () => Navigator.pop(context, d)),
            ],
          ]),
        ),
        if (d == null && !_thinking)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: TextField(
                controller: _input,
                autofocus: true,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Type your answer…',
                  suffixIcon: IconButton(icon: const Icon(Icons.send), tooltip: 'Send', onPressed: _send),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
