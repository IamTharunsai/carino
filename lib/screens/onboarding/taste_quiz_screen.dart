import 'package:flutter/material.dart';
import '../../models/experience.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Taste Quiz — eight playful This-or-That picks that tune the Daily Drop
/// and power the honest "Why you're seeing them" line on cards.
///
/// Honesty: no camera-roll scanning, every question skippable, answers
/// editable from You, and the overlap shown to a viewer is always real.
class TasteQuizScreen extends StatefulWidget {
  const TasteQuizScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<TasteQuizScreen> createState() => _TasteQuizScreenState();
}

class _TasteQuizScreenState extends State<TasteQuizScreen> {
  late final Map<String, String> _answers = {...Services.prefs.tasteAnswers};
  int _index = 0;

  void _pick(String? answer) {
    final q = tasteQuiz[_index];
    setState(() {
      if (answer == null) {
        _answers.remove(q.id);
      } else {
        _answers[q.id] = answer;
      }
      if (_index < tasteQuiz.length - 1) {
        _index++;
      } else {
        _finish();
      }
    });
  }

  void _finish() {
    Services.prefs.tasteAnswers = _answers;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final q = tasteQuiz[_index];
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Taste quiz', style: text.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Quick picks that tune your Daily Drop. Matching answers show '
              'up as conversation starters — skip anything.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_index + 1) / tasteQuiz.length,
              color: AppColors.emberCrimson,
            ),
            const SizedBox(height: 6),
            Text('${_index + 1} of ${tasteQuiz.length}', style: text.bodySmall),
            const Spacer(),
            Text(q.prompt,
                style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            for (final option in [q.a, q.b]) ...[
              GlassContainer(
                opacity: _answers[q.id] == option ? 0.9 : null,
                onTap: () => _pick(option),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(option, style: text.titleMedium),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: () => _pick(null),
              child: const Text('Skip this one'),
            ),
            const Spacer(),
            SparkButton(
              label: 'Finish later',
              secondary: true,
              icon: Icons.check,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }
}
