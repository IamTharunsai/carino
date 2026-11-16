import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/plan_split_card.dart';
import '../../widgets/safety_alert.dart';
import '../you/trusted_contacts_screen.dart';
import 'decompress_screens.dart';
import 'plan_composer_screen.dart';

/// S-040 Plan Detail — one plan, both people, honest states:
/// proposed -> both confirm -> confirmed (with day-of check-ins:
/// "I'm here" / "Home safe") -> completed. Change/decline paths use
/// polite templates — nobody is ghosted by UI design. Public place TYPES
/// only; no private addresses ever render here.
class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({
    super.key,
    required this.member,
    required this.placeType,
    required this.timeLabel,
    this.confirmed = false,
    this.upcoming = true,
    this.planId,
  });

  final Member member;
  final String placeType;
  final String timeLabel;
  final bool confirmed;
  final bool upcoming;
  final String? planId;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late bool _confirmed = widget.confirmed;
  bool _arrived = false;
  bool _homeSafe = false;
  bool _cancelled = false;

  // Date Check-in (free forever): venue + time + match's first name shared
  // with ONE trusted contact if a check-in is missed. Never live GPS.
  String _checkInAt = '22:00';
  bool _checkInActive = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final member = widget.member;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        backgroundImage: AssetImage(member.photoAsset)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          '${widget.placeType} with ${member.firstName}',
                          style: text.titleLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.timeLabel, style: text.titleMedium),
                const SizedBox(height: 6),
                Chip(
                  label: Text(_cancelled
                      ? 'Cancelled — kindly'
                      : _confirmed
                          ? 'Both confirmed'
                          : 'Waiting for ${member.firstName} to confirm'),
                  backgroundColor:
                      AppColors.emberCrimson.withValues(alpha: 0.2),
                  side: BorderSide.none,
                ),
                const SizedBox(height: 8),
                Text(
                  'Public place type only — the exact spot is yours to '
                  'agree in chat. Either of you can change or cancel, '
                  'any time, no questions asked.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!_confirmed && !_cancelled) ...[
            SparkButton(
              label: 'Confirm plan',
              icon: Icons.check_circle_outline,
              onPressed: () => setState(() => _confirmed = true),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Propose a change',
              secondary: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlanComposerScreen(member: member),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Decline kindly',
              secondary: true,
              onPressed: () => _politeSheet(
                title: 'Decline this plan?',
                template:
                    '“Thanks for suggesting it — I can\'t make that one. Another time?” Nothing meaner is needed, and they\'ll never see a harsher version.',
              ),
            ),
          ],
          if (_confirmed && widget.upcoming && !_cancelled) ...[
            Text('On the day', style: text.titleMedium),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Book it — table, tickets, stay',
              icon: Icons.confirmation_number_outlined,
              onPressed: () => _bookSheet(member),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Start Phone-Down together',
              icon: Icons.phonelink_lock_outlined,
              onPressed: () => openPhoneDown(context,
                  planTitle: '${widget.placeType} with ${member.firstName}'),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: _arrived ? 'You\'re checked in ✓' : 'I\'m here',
              icon: Icons.place_outlined,
              secondary: _arrived,
              onPressed:
                  _arrived ? null : () => setState(() => _arrived = true),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: _homeSafe ? 'Home safe ✓' : 'I’m home safe',
              icon: Icons.home_outlined,
              secondary: _homeSafe,
              onPressed: _homeSafe
                  ? null
                  : () {
                      setState(() => _homeSafe = true);
                      if (Services.prefs.trustedContacts.isNotEmpty) sendHomeSafe(context);
                    },
            ),
            Text('Tap when you’re back home: it ends the check-in and lets your people know you’re OK.',
                style: text.bodySmall),
            const SizedBox(height: 8),
            SparkButton(
              label: 'I don’t feel safe',
              icon: Icons.sos_outlined,
              secondary: true,
              onPressed: () => showSosSheet(context),
            ),
            const SizedBox(height: 6),
            Text(
              'Check-ins are shared only with ${member.firstName}, only '
              'for this plan.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 10),
            SparkButton(
              label: 'Add to calendar',
              secondary: true,
              icon: Icons.event_outlined,
              onPressed: () => launchUrl(Uri.parse(
                  'https://calendar.google.com/calendar/render?action=TEMPLATE'
                  '&text=${Uri.encodeComponent('${widget.placeType} with ${member.firstName}')}'
                  '&details=${Uri.encodeComponent('${widget.timeLabel} · planned on Cariño 💛')}'),
                  mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Reschedule',
              secondary: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlanComposerScreen(member: member),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'Cancel kindly',
              secondary: true,
              onPressed: () => _politeSheet(
                title: 'Cancel this plan?',
                template:
                    '“I\'m so sorry — something\'s come up and I can\'t make it. You deserve a heads-up, not silence.”',
                confirmCancel: true,
              ),
            ),
          ],
          if (_confirmed && widget.upcoming && !_cancelled) ...[
            const SizedBox(height: 14),
            _checkInCard(text, member),
          ],
          const SizedBox(height: 14),
          if (!_cancelled) ...[
            PlanSplitCard(
                planKey: widget.planId ??
                    '${member.id}|${widget.placeType}|${widget.timeLabel}',
                otherId: member.id,
                otherName: member.firstName),
            const SizedBox(height: 14),
          ],
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meeting safely', style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '• Public place, your own transport.\n'
                  '• Tell a friend where you\'ll be.\n'
                  '• Share-your-trip lives in Trust & Safety.\n'
                  '• Leave anytime — no explanation owed.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkInCard(TextTheme text, Member member) {
    final prefs = Services.prefs;
    final hasContact = prefs.trustedContactName.isNotEmpty;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_moon_outlined,
                  color: AppColors.sparkCoral),
              const SizedBox(width: 8),
              Expanded(child: Text('Date check-in', style: text.titleMedium)),
              const Chip(
                label: Text('Free'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!hasContact) ...[
            Text(
              'Add your trusted people. If you miss a check-in, they get the '
              'venue, time and ${member.firstName}\'s first name and photo.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 10),
            SparkButton(
              label: 'Add trusted contacts',
              icon: Icons.person_add_alt_outlined,
              secondary: true,
              onPressed: _addContact,
            ),
          ] else if (!_checkInActive) ...[
            Text('Trusted contact: ${prefs.trustedContactName}',
                style: text.bodyMedium),
            const SizedBox(height: 8),
            Text('Check on me at', style: text.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final t in ['21:00', '22:00', '23:00', '00:00'])
                  ChoiceChip(
                    label: Text(t),
                    selected: _checkInAt == t,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) => setState(() => _checkInAt = t),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SparkButton(
              label: 'Start check-in',
              icon: Icons.shield_outlined,
              onPressed: () => setState(() => _checkInActive = true),
            ),
            TextButton(
              onPressed: _addContact,
              child: const Text('Edit contacts'),
            ),
          ] else ...[
            Text(
              'Active. We\'ll ask "Are you OK?" at $_checkInAt. No answer in '
              '15 minutes and ${prefs.trustedContactName} gets your plan '
              'details, plus a prompt to call you.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 10),
            SparkButton(
              label: 'I\'m safe — end check-in',
              icon: Icons.check_circle_outline,
              onPressed: () {
                setState(() {
                  _checkInActive = false;
                  _homeSafe = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Check-in ended. Nothing was shared.')),
                );
              },
            ),
            const SizedBox(height: 8),
            SparkButton(
              label: 'I need help now',
              icon: Icons.sos_outlined,
              secondary: true,
              onPressed: () => showSosSheet(context),
            ),
          ],
        ],
      ),
    );
  }

  void _bookSheet(Member member) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Book for ${widget.placeType}', style: Theme.of(s).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Opens the booking site with your plan filled in.', style: Theme.of(s).textTheme.bodySmall),
          for (final k in kindsFor(widget.placeType))
            ListTile(
              leading: Text(k.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(k.label),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () {
                Navigator.pop(s);
                launchUrl(bookingUri(k, widget.placeType, member.city), mode: LaunchMode.externalApplication);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _addContact() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TrustedContactsScreen()));
    if (mounted) setState(() {});
  }

  void _politeSheet({
    required String title,
    required String template,
    bool confirmCancel = false,
  }) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(template, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          SparkButton(
            label: 'Send this message',
            onPressed: () {
              Navigator.of(context).pop();
              if (confirmCancel) setState(() => _cancelled = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent in your chat.')),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Write my own instead'),
          ),
        ],
      ),
    );
  }
}

/// Convenience: open the detail for a stored [MockPlan].
void openMockPlan(BuildContext context, MockPlan plan) {
  final member = MockData.memberById(plan.memberId);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlanDetailScreen(
        planId: plan.id,
        member: member,
        placeType: plan.placeType,
        timeLabel: plan.timeLabel,
        confirmed: plan.state == 'confirmed',
        upcoming: plan.upcoming,
      ),
    ),
  );
}
