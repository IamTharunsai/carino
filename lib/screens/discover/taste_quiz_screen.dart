import 'package:flutter/material.dart';

import '../../services/services.dart';
import '../../state/taste_quiz.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Wave 3 · Taste Quiz (CROWD-FEATURES #20).
///
/// Six questions; every answer maps to real tune terms (state/
/// taste_quiz.dart). Finishing writes the resulting TuneParse to the
/// store (the deck re-orders immediately, through the same matcher as
/// a typed tune) AND persists the terms to UserPrefs, so the taste
/// survives restarts. Retaking REPLACES the previous answers — stated
/// on screen, enforced in the write.
class TasteQuizScreen extends StatefulWidget {
  const TasteQuizScreen({super.key});

  @override
  State<TasteQuizScreen> createState() => _TasteQuizScreenState();
}

class _TasteQuizScreenState extends State<TasteQuizScreen> {
  final Map<int, int> _answers = {};
  bool _done = false;

  bool get _complete => _answers.length >= tasteQuizQuestions.length;

  void _finish() {
    final tune = tuneFromQuizAnswers(_answers);
    Services.store.setTune(tune);
    Services.prefs.tasteBoostTerms = tune.boost;
    Services.prefs.tasteDropTerms = tune.drop;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (_done) {
      final tune = tuneFromQuizAnswers(_answers);
      return GlassScaffold(
        appBar: AppBar(title: const Text('Taste Quiz')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.auto_awesome_outlined,
                      size: 34, color: AppColors.sparkCoral),
                  const SizedBox(height: 10),
                  Text('Your Drop is tuned to your taste',
                      style: text.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    tune.isEmpty
                        ? 'You picked "keep it mixed" — no boost, no '
                            'removals. The Drop stays as it was.'
                        : 'From your answers:\n'
                            '${[
                              for (final t in tune.boost) 'more $t',
                              for (final t in tune.drop) 'less $t',
                            ].join(' · ')}',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Saved on this device — your Drop opens with this '
                    'taste next time too. A manual Tune My Drop or a '
                    'retake replaces it whenever you like.',
                    style: text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Back to Discover',
              icon: Icons.check_circle_outline,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
    return GlassScaffold(
      appBar: AppBar(title: const Text('Taste Quiz')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Six quick picks. They tune your Drop to what you actually '
            'like — real profile signals only, never watch-time bait. '
            'Retaking replaces your last quiz, completely.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (var q = 0; q < tasteQuizQuestions.length; q++) ...[
            Text(tasteQuizQuestions[q].question,
                style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var o = 0; o < tasteQuizQuestions[q].options.length; o++)
                  ChoiceChip(
                    label: Text(tasteQuizQuestions[q].options[o].label),
                    selected: _answers[q] == o,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) => setState(() => _answers[q] = o),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          SparkButton(
            label: _complete
                ? 'Tune my Drop'
                : 'Answer all six (${_answers.length}/6)',
            icon: Icons.auto_awesome_outlined,
            onPressed: _complete ? _finish : null,
          ),
        ],
      ),
    );
  }
}
