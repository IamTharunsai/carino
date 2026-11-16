import 'package:flutter/material.dart';
import '../../models/host_tools.dart';

import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import 'plans_hub_screen.dart';

/// Wave 1 · Post→Plan composer (CROWD-FEATURES #9).
///
/// Turns a spark — a chat with a match, a Moment someone posted — into an
/// OPEN group plan other verified members can join. Deliberately a
/// different object from the 1:1 S-039 suggestion: this plan is hosted
/// by you, listed in the Plans hub / Tonight Near Me, and joinable.
///
/// Safety rails inherited from S-039: PUBLIC place types only (never a
/// home address), the plan is visible to verified members only, and the
/// composer says so. The persistent hint line names exactly what's
/// missing before Post enables — the S-039 pattern.
class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key, this.fromMember, this.fromMoment});

  /// Set when the plan starts from a chat with this member.
  final Member? fromMember;

  /// Set when the plan starts from this member's Moment.
  final Moment? fromMoment;

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  static const _placeTypes = [
    'Coffee',
    'Gallery',
    'Street-food market',
    'Park walk',
    'Live music',
    'Bookstore',
    'Arcade bar',
    'Farmers market',
  ];

  static const _timeOptions = [
    'Tonight · 19:00',
    'Tonight · 20:30',
    'Tomorrow · 18:30',
    'Sat · 11:00',
    'Sat · 16:00',
    'Sun · 12:00',
  ];

  final TextEditingController _title = TextEditingController();
  final TextEditingController _placeDetail = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _code = TextEditingController();
  String? _placeType;
  String? _timeLabel;
  int _groupSize = 4;
  bool _instantJoin = true;

  Member? get _sourceMember => widget.fromMember ?? widget.fromMoment?.member;

  String? get _sourceLabel {
    if (widget.fromMoment != null) {
      return "From ${_sourceMember!.firstName}'s Moment";
    }
    if (widget.fromMember != null) {
      return 'From your chat with ${_sourceMember!.firstName}';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // From a Moment, the plan starts as a response to it — the title is
    // prefilled from the caption, editable, never locked.
    final moment = widget.fromMoment;
    if (moment != null) {
      final caption = moment.caption.trim();
      _title.text = caption.isEmpty
          ? 'Join ${_sourceMember!.firstName} out'
          : (caption.length <= 42 ? caption : '${caption.substring(0, 42)}…');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _placeDetail.dispose();
    _note.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _ready =>
      _title.text.trim().isNotEmpty && _placeType != null && _timeLabel != null;

  String get _hint {
    if (_title.text.trim().isEmpty) return 'Give the plan a title first.';
    if (_placeType == null) return 'Pick a place type — public places only.';
    if (_timeLabel == null) return 'Now pick a time.';
    return 'Ready — verified members nearby can find this in Plans and Tonight Near Me.';
  }

  void _post() {
    if (!_ready) return;
    final detail = _placeDetail.text.trim();
    final place = detail.isEmpty ? _placeType! : '$_placeType · $detail';
    final plan = Services.store.createPlan(
      title: _title.text,
      place: place,
      timeLabel: _timeLabel!,
      tonight: _timeLabel!.startsWith('Tonight'),
      groupSize: _groupSize,
      instantJoin: _instantJoin,
      sourceLabel: _sourceLabel,
      note: [
        _note.text.trim(),
        if (cleanCheckInCode(_code.text) case final c?) 'Check-in code: $c',
      ].where((s) => s.isNotEmpty).join(' · '),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Plan posted: "${plan.title}" — it\'s live in Plans near you.'),
      ),
    );
    // Land the member on the hub so the plan is visibly REAL (in the
    // list, hosted by them), not just a toast claim.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const PlansHubScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassScaffold(
      appBar: AppBar(title: const Text('Make it a plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (_sourceMember != null) ...[
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage(_sourceMember!.photoAsset),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.fromMoment != null
                          ? 'Inspired by ${_sourceMember!.firstName}\'s Moment — turn it into a real plan.'
                          : 'From your chat with ${_sourceMember!.firstName} — make it a group plan.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text('What\'s the plan?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            maxLength: 60,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Arcade night + milkshakes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Where? (public place types only)',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _placeTypes)
                ChoiceChip(
                  label: Text(p),
                  selected: _placeType == p,
                  selectedColor: AppColors.blush,
                  labelStyle: TextStyle(
                    color: _placeType == p
                        ? AppColors.emberCrimson
                        : theme.textTheme.bodyLarge?.color,
                  ),
                  onSelected: (_) => setState(() => _placeType = p),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _placeDetail,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Area or venue name (optional)',
              hintText: 'e.g. Short North',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('When?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _timeOptions)
                ChoiceChip(
                  label: Text(t),
                  selected: _timeLabel == t,
                  selectedColor: AppColors.blush,
                  labelStyle: TextStyle(
                    color: _timeLabel == t
                        ? AppColors.emberCrimson
                        : theme.textTheme.bodyLarge?.color,
                  ),
                  onSelected: (_) => setState(() => _timeLabel = t),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Group size', style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _groupSize > 2
                    ? () => setState(() => _groupSize--)
                    : null,
              ),
              Text('$_groupSize',
                  style: theme.textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _groupSize < 8
                    ? () => setState(() => _groupSize++)
                    : null,
              ),
            ],
          ),
          Text(
            'Including you. Small on purpose — a group that fits one table actually talks.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Anyone verified can join'),
            subtitle: const Text(
                'Off = people request, and you approve each join.'),
            value: _instantJoin,
            onChanged: (v) => setState(() => _instantJoin = v),
          ),
          TextField(
            controller: _code,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Check-in code (optional)',
              hintText: 'e.g. SUNRUN — guests say it when they arrive',
            ),
          ),
          TextField(
            controller: _note,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Note for joiners (optional)',
              hintText: 'e.g. Easy pace, nobody gets left behind.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 16, color: AppColors.sparkCoral),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Public places only — never a home address. Only verified '
                  'members can see or join plans, and Check-In Safety stays '
                  'one tap away in the plan chat.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_hint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          SparkButton(
            label: 'Post plan',
            icon: Icons.event_available_outlined,
            onPressed: _ready ? _post : null,
          ),
        ],
      ),
    );
  }
}
