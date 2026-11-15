import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../models/sync.dart';
import '../../services/services.dart';
import 'plan_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-039 Plan Composer — suggest a REAL plan (public place type + time).
/// AI-07 can draft the note; the member reviews and sends it themselves.
/// Plan confirmed (S-040) plays the warm confirmation tone + drawn check.
class PlanComposerScreen extends StatefulWidget {
  const PlanComposerScreen({super.key, required this.member});

  final Member member;

  @override
  State<PlanComposerScreen> createState() => _PlanComposerScreenState();
}

class _PlanComposerScreenState extends State<PlanComposerScreen> {
  String? _selectedId;
  String? _timeChip;
  final TextEditingController _note = TextEditingController();
  bool _drafting = false;

  /// S-039 time chips — seeded from the member's stated availability so
  /// suggestions land when they're actually free (S-008 pays off here).
  List<String> get _timeOptions {
    final a = widget.member.availability;
    if (a == 'Tonight') return const ['Tonight · 19:00', 'Tonight · 20:30', 'Tomorrow · 19:00'];
    if (a == 'Weekends') return const ['Sat · 11:00', 'Sat · 16:00', 'Sun · 12:00'];
    return const ['Tomorrow · 18:30', 'Sat · 11:00', 'Sun · 16:00'];
  }

  bool _allowed(String t) => firstMeetAllowed(
        t,
        mine: Services.prefs.myComfort,
        theirs: widget.member.comfort,
        met: Services.trust.hasMet(widget.member.id),
      );

  Future<void> _aiDraft() async {
    // AI-07: draft only. Nothing is sent until the member taps Send.
    setState(() => _drafting = true);
    final idea = MockData.planIdeas.firstWhere((p) => p.id == _selectedId,
        orElse: () => MockData.planIdeas.first);
    final text = await Services.ai.draftPlanNote(placeType: idea.placeType);
    if (!mounted) return;
    setState(() {
      _drafting = false;
      _note.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: Text('Plan with ${widget.member.firstName}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Public places, clear times, easy exits — for both of you.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final idea in MockData.planIdeas) ...[
            GlassContainer(
              opacity: _selectedId == idea.id ? 0.85 : null,
              onTap: () => setState(() => _selectedId = idea.id),
              child: Row(
                children: [
                  Icon(
                    _selectedId == idea.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: AppColors.sparkCoral,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${idea.placeType} · ${idea.timeLabel}',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(idea.note, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text('When? (${widget.member.firstName} is usually free: ${widget.member.availability})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _timeOptions)
                ChoiceChip(
                  label: Text(t),
                  selected: _timeChip == t,
                  selectedColor: AppColors.emberCrimson,
                  // Comfort rule: daytime first meet (either person's) greys
                  // out evening times until you've met.
                  onSelected: _allowed(t) ? (_) => setState(() => _timeChip = t) : null,
                ),
            ],
          ),
          if (_timeOptions.any((t) => !_allowed(t)))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "Evening times are off: a daytime first meet was asked for "
                "(comfort rules). They open up once you've met.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 14),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('First-plan safety, always',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Public place · your own transport · tell a friend. '
                  'These tips are never hidden behind Plus.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Your note (in your words)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SparkButton(
            label: _drafting ? 'Drafting…' : 'Draft it with AI (you still send it)',
            icon: Icons.auto_awesome_outlined,
            secondary: true,
            onPressed: _selectedId == null || _drafting ? null : _aiDraft,
          ),
          const SizedBox(height: 12),
          SparkButton(
            label: 'Send plan suggestion',
            icon: Icons.send_outlined,
            onPressed: _selectedId == null || _timeChip == null
                ? null
                : () {
                    // S-040: the suggestion opens its detail; on their
                    // confirm, the plan card pins in chat.
                    Services.sound.gentleHaptic();
                    final idea = MockData.planIdeas
                        .firstWhere((p) => p.id == _selectedId);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => PlanDetailScreen(
                          member: widget.member,
                          placeType: idea.placeType,
                          timeLabel: _timeChip!,
                        ),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Plan sent to ${widget.member.firstName}. It pins in your chat when they confirm.',
                        ),
                      ),
                    );
                  },
          ),
          if (_selectedId != null && _timeChip == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Pick a time to send.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
