import 'package:flutter/material.dart';

import '../../models/agent.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Wave 4 · Outcome Graph check-in (MASTER-BUILD-PLAN A3).
///
/// "Did it happen?" — one tap per past plan, Table and club night the
/// member was part of. The four answers write an [OutcomeRecord] in
/// the store; the record then feeds host standing, Tables standing's
/// context and the Presence dashboard. One record per subject: once
/// answered, a prompt leaves this list everywhere (the store derives
/// the list from subjects minus records).
///
/// Private by design: an outcome is the member's own attestation —
/// it is never shown to the other members as a public rating.
class OutcomeCheckInScreen extends StatefulWidget {
  const OutcomeCheckInScreen({super.key});

  @override
  State<OutcomeCheckInScreen> createState() => _OutcomeCheckInScreenState();
}

class _OutcomeCheckInScreenState extends State<OutcomeCheckInScreen> {
  /// The in-progress pick per subject id — nothing is written until
  /// "Save check-in" is tapped, so a stray chip tap changes nothing.
  final Map<String, OutcomeRating> _picks = {};

  void _save(OutcomePrompt prompt) {
    final rating = _picks[prompt.subjectId];
    if (rating == null) return;
    final record = Services.store.recordOutcome(
      kind: prompt.subjectKind,
      subjectId: prompt.subjectId,
      rating: rating,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(record == null
            ? 'That one was already checked in — one record per night.'
            : 'Checked in: "${prompt.title}" — ${rating.label}. '
                'Thanks; it shapes what gets suggested next.'),
      ),
    );
    setState(() => _picks.remove(prompt.subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final pending = store.pendingOutcomePrompts();
        final recorded = store.outcomeRecords;
        return GlassScaffold(
          appBar: AppBar(title: const Text('How did it go?')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Text(
                'Plans only count when they actually happen. One tap '
                'per night — your answer is private, and it\'s what '
                'host standing and your Presence are built from.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (pending.isEmpty)
                GlassContainer(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 34),
                      const SizedBox(height: 10),
                      Text('All caught up',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Nothing is waiting for a check-in. When a '
                        'plan, Table or club night you joined is over, '
                        'it lands here.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (final prompt in pending) ...[
                  _promptCard(context, prompt),
                  const SizedBox(height: 12),
                ],
              if (recorded.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Your check-ins', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final record in recorded.reversed) ...[
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.subjectTitle,
                                  style: theme.textTheme.titleMedium),
                              Text(
                                '${record.subjectDetail} · '
                                'checked in ${record.dateLabel.toLowerCase()}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Chip(
                          label: Text(record.rating.label),
                          backgroundColor: record.rating.happened
                              ? AppColors.emberCrimson
                                  .withValues(alpha: 0.25)
                              : null,
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _promptCard(BuildContext context, OutcomePrompt prompt) {
    final theme = Theme.of(context);
    final pick = _picks[prompt.subjectId];
    final icon = switch (prompt.subjectKind) {
      OutcomeSubjectKind.plan => Icons.event_outlined,
      OutcomeSubjectKind.table => Icons.restaurant_outlined,
      OutcomeSubjectKind.ticket => Icons.confirmation_number_outlined,
    };
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.sparkCoral),
              const SizedBox(width: 7),
              Text(prompt.subjectKind.label,
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(prompt.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(prompt.detailLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text('Did it happen?', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rating in OutcomeRating.values)
                ChoiceChip(
                  label: Text(rating.label),
                  selected: pick == rating,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) =>
                      setState(() => _picks[prompt.subjectId] = rating),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SparkButton(
            label: 'Save check-in',
            icon: Icons.check_circle_outline,
            onPressed: pick == null ? null : () => _save(prompt),
          ),
        ],
      ),
    );
  }
}
