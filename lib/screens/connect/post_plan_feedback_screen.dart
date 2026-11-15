import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../models/sync.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';

/// S-042 Post-Plan Feedback (P1) — after a plan: did it happen, were you
/// comfortable, was it worthwhile? Private by default; NOTHING here is
/// shown to the other person as a rating — there are no public scores of
/// people in this app. A discomfort signal routes to Trust (with a report
/// link), because feedback is a safety sensor, not a review site.
class PostPlanFeedbackScreen extends StatefulWidget {
  const PostPlanFeedbackScreen({
    super.key,
    required this.member,
    required this.placeType,
  });

  final Member member;
  final String placeType;

  @override
  State<PostPlanFeedbackScreen> createState() =>
      _PostPlanFeedbackScreenState();
}

class _PostPlanFeedbackScreenState extends State<PostPlanFeedbackScreen> {
  bool? _happened;
  bool? _comfortable;
  bool? _worthwhile;
  final TextEditingController _comment = TextEditingController();
  bool _done = false;
  String? _tip;
  final Set<ReflectTag> _liked = {};
  final Set<ReflectTag> _disliked = {};

  Future<void> _save() async {
    final tip = await Services.ai.debriefTip(
      happened: _happened ?? false,
      comfortable: _comfortable ?? true,
      worthwhile: _worthwhile ?? true,
    );
    if (!mounted) return;
    // Private check-in: only ever reorders MY suggestions; never shared.
    Services.prefs.reflections.add(Reflection(
      category: categoryForPlace(widget.placeType),
      good: (_happened ?? false) && (_comfortable ?? true) && (_worthwhile ?? true),
      liked: {..._liked},
      disliked: {..._disliked},
    ));
    await Services.prefs.save();
    if (!mounted) return;
    setState(() {
      _tip = tip;
      _done = true;
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Widget _question(String label, bool? value, ValueChanged<bool> onPick) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          ChoiceChip(
            label: const Text('Yes'),
            selected: value == true,
            onSelected: (_) => setState(() => onPick(true)),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('No'),
            selected: value == false,
            onSelected: (_) => setState(() => onPick(false)),
          ),
        ],
      ),
    );
  }

  Widget _tags(String title, Set<ReflectTag> set, Set<ReflectTag> other) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in ReflectTag.values)
              FilterChip(
                label: Text(t.label),
                selected: set.contains(t),
                onSelected: (on) => setState(() {
                  if (on) {
                    set.add(t);
                    other.remove(t);
                  } else {
                    set.remove(t);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return GlassScaffold(
        appBar: AppBar(title: const Text('Thanks')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Feedback saved — privately. It\'s never shown to '
                '${widget.member.firstName} as a score.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (_tip != null) ...[
                const SizedBox(height: 16),
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_outlined,
                              size: 16, color: AppColors.sparkCoral),
                          SizedBox(width: 6),
                          Expanded(child: Text('Debrief · AI suggestion, just for you')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_tip!,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SparkButton(
                label: 'Done',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }
    return GlassScaffold(
      appBar: AppBar(title: const Text('How did it go?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.placeType} with ${widget.member.firstName} — three '
            'quick questions. Only Trust & Safety sees discomfort signals.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          GlassContainer(
            child: Column(
              children: [
                _question('Did the plan happen?', _happened,
                    (v) => _happened = v),
                _question('Did you feel comfortable?', _comfortable,
                    (v) => _comfortable = v),
                _question('Was it worthwhile?', _worthwhile,
                    (v) => _worthwhile = v),
              ],
            ),
          ),
          if (_comfortable == false) ...[
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We\'re sorry. If something happened, reporting helps '
                    'protect everyone — and it stays anonymous to them.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  SparkButton(
                    label: 'Report something about this plan',
                    secondary: true,
                    onPressed: () => SafetyActions.showReportFlow(
                      context,
                      member: widget.member,
                      surface: 'Post-plan feedback',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _tags('What felt good?', _liked, _disliked),
          const SizedBox(height: 8),
          _tags("What didn't?", _disliked, _liked),
          Text('Private: this only tunes your own suggestions.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Private debrief note (only you see it)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SparkButton(
            label: 'Save feedback',
            onPressed: _happened == null ? null : _save,
          ),
        ],
      ),
    );
  }
}
