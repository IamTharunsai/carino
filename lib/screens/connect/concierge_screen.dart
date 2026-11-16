import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/agent.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../state/concierge.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Wave 4 · AI Concierge (MASTER-BUILD-PLAN A1) — "Plan it for me".
///
/// The member states an intent in plain words; the Concierge proposes
/// up to three REAL options (a Table night, an open plan, a club
/// night, or a new-plan draft), each with its price up front and a
/// WHY line from real fields; the member's tap books through the
/// store's real actions, and the confirmation shows what was booked,
/// the price, and the reminder state.
///
/// HONEST LABELLING: this build's Concierge matches words to real
/// plans/tables/tickets with rules (state/concierge.dart) — it is not
/// a live AI, and this screen says so. The live AI brain plugs into
/// the same propose → confirm → book flow at hosting.
class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key, this.fromMember});

  /// Set when opened from a chat: a new-plan draft is then sourced
  /// from that conversation ('From your chat with Aria').
  final Member? fromMember;

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  final TextEditingController _input = TextEditingController();
  List<ConciergeProposal>? _proposals;
  ConciergeExecution? _result;
  String _askedText = '';

  static const List<String> _examples = [
    'Dinner Friday, quiet, 4 of us',
    'Something calm outdoors Sunday',
    'Club night Saturday',
    'Live music tonight',
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _ask(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _askedText = trimmed;
      _result = null;
      _proposals = conciergeProposals(
        Services.store,
        trimmed,
        fromMember: widget.fromMember,
      );
    });
  }

  void _book(ConciergeProposal proposal) {
    final execution = executeConciergeProposal(
      Services.store,
      proposal,
      fromMember: widget.fromMember,
    );
    setState(() {
      _result = execution;
      if (execution.ok) _proposals = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassScaffold(
      appBar: AppBar(title: const Text('Plan it for me')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Text(
            widget.fromMember != null
                ? 'Tell me what you and ${widget.fromMember!.firstName} '
                    'feel like — I\'ll find it on the board, or draft '
                    'the plan for you.'
                : 'Tell me what you feel like — dinner, something calm, '
                    'a night out. I\'ll find it on the board, or draft '
                    'the plan for you.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 17, color: AppColors.sparkCoral),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Concierge · demo brain — in this build it matches '
                    'your words against real plans, Tables nights and '
                    'club tickets with rules, not a live AI. The live '
                    'AI plugs into this same flow at hosting. Prices '
                    'are always shown before you confirm.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            textInputAction: TextInputAction.search,
            onSubmitted: _ask,
            decoration: const InputDecoration(
              labelText: 'What are you in the mood for?',
              hintText: 'e.g. dinner Friday, quiet, 4 of us',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in _examples)
                ActionChip(
                  label: Text(example),
                  onPressed: () {
                    _input.text = example;
                    _ask(example);
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          SparkButton(
            label: 'Plan it',
            icon: Icons.auto_awesome_outlined,
            onPressed: () => _ask(_input.text),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _resultCard(context, _result!),
          ],
          if (_proposals != null) ...[
            const SizedBox(height: 20),
            Text('For "$_askedText"',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Real options from tonight\'s board — nothing here is '
              'invented, and booking uses the same actions as booking '
              'by hand.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _proposals!.length; i++) ...[
              _proposalCard(context, _proposals![i])
                  .animate()
                  .fadeIn(delay: (70 * i).ms, duration: 300.ms),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  Widget _proposalCard(BuildContext context, ConciergeProposal proposal) {
    final theme = Theme.of(context);
    final icon = switch (proposal.kind) {
      ConciergeProposalKind.table => Icons.restaurant_outlined,
      ConciergeProposalKind.plan => Icons.event_outlined,
      ConciergeProposalKind.ticket => Icons.confirmation_number_outlined,
      ConciergeProposalKind.newPlan => Icons.add_circle_outline,
    };
    final kindLabel = switch (proposal.kind) {
      ConciergeProposalKind.table => 'Cariño Tables',
      ConciergeProposalKind.plan => 'Open plan',
      ConciergeProposalKind.ticket => 'Club night',
      ConciergeProposalKind.newPlan => 'New plan · you host',
    };
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.sparkCoral),
              const SizedBox(width: 7),
              Text(kindLabel, style: theme.textTheme.bodySmall),
              const Spacer(),
              if (proposal.priceLabel != null)
                Text(
                  proposal.priceLabel!,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: AppColors.sparkCoral),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(proposal.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(proposal.detailLabel, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('Why this: ${proposal.whyLine}',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          SparkButton(
            label: proposal.actionLabel,
            icon: Icons.check_circle_outline,
            onPressed: () => _book(proposal),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, ConciergeExecution result) {
    final theme = Theme.of(context);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.ok
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 20,
                color: AppColors.sparkCoral,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result.headline,
                    style: theme.textTheme.titleMedium),
              ),
              if (result.priceLabel != null)
                Text(
                  result.priceLabel!,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: AppColors.sparkCoral),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.detail, style: theme.textTheme.bodyMedium),
          if (result.reminderLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.alarm_outlined,
                    size: 16, color: AppColors.sparkCoral),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(result.reminderLabel!,
                      style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            result.ok
                ? 'Booked through the same store actions as booking by '
                    'hand — it\'s in the Plans hub (and My Tickets, for '
                    'club nights) right now.'
                : 'Nothing was booked. Ask again with different words '
                    'and I\'ll re-check the board.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
