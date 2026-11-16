import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/mock_data.dart';
import '../../models/plan.dart';
import '../../models/presence.dart';
import '../../services/services.dart';
import '../../state/presence.dart' as presence_logic;
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/spark_button.dart';
import 'concierge_screen.dart';
import 'create_plan_screen.dart';
import 'outcome_checkin_screen.dart';
import 'phone_down_screen.dart';
import 'tables_screen.dart';
import 'tickets_screen.dart';

/// Wave 1 · Plans hub + Tonight Near Me (CROWD-FEATURES #9/#10).
///
/// The home for OPEN group plans: everything happening tonight, your
/// plans, and everything else on the board — plus the Cariño Tables
/// banner and your Tables booking when one exists. Reachable from the
/// Connect tab and the Discover Tonight strip; the bottom tabs stay
/// five (this is a pushed screen, not a tab).
class PlansHubScreen extends StatefulWidget {
  const PlansHubScreen({super.key, this.tonightOnly = false});

  /// Opened from the Tonight strip: start on the Tonight filter.
  final bool tonightOnly;

  @override
  State<PlansHubScreen> createState() => _PlansHubScreenState();
}

enum _HubFilter { all, tonight, mine }

/// Wave 3 · one Decompress shelf card (#12): the compact form of a
/// calm plan — same store state as the full PlanCard below it, so a
/// join here and a join there can never disagree.
class _DecompressCard extends StatelessWidget {
  const _DecompressCard({required this.plan, required this.onJoinToggle});

  final OpenPlan plan;
  final VoidCallback onJoinToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final host = plan.hostedByMe
        ? MockData.currentUser
        : MockData.memberById(plan.hostId);
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_outlined,
                  size: 16, color: AppColors.sparkCoral),
              const SizedBox(width: 6),
              Text('Decompress', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.title,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${plan.place} · ${plan.timeLabel}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(
            'Hosted by ${host.firstName} · '
            '${plan.isFull ? 'Full · ${plan.groupSize} going' : '${plan.spotsLeft} spot${plan.spotsLeft == 1 ? '' : 's'} left'}',
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          SparkButton(
            label: switch (plan.myState) {
              PlanJoinState.going =>
                plan.hostedByMe ? 'You\'re hosting' : 'You\'re in — tap to leave',
              PlanJoinState.requested => 'Requested — tap to cancel',
              PlanJoinState.none =>
                plan.isFull ? 'Plan full' : 'Join plan',
            },
            secondary: plan.myState != PlanJoinState.none,
            onPressed: plan.hostedByMe ||
                    (plan.isFull && plan.myState == PlanJoinState.none)
                ? null
                : onJoinToggle,
          ),
        ],
      ),
    );
  }
}

class _PlansHubScreenState extends State<PlansHubScreen> {
  late _HubFilter _filter =
      widget.tonightOnly ? _HubFilter.tonight : _HubFilter.all;

  /// The board shows JOINABLE plans only — past plans (Wave 4) leave
  /// the board and live in the outcome check-in + Presence instead.
  List<OpenPlan> _visible(List<OpenPlan> plans) => switch (_filter) {
        _HubFilter.all => plans.where((p) => !p.past).toList(),
        _HubFilter.tonight =>
          plans.where((p) => p.tonight && !p.past).toList(),
        _HubFilter.mine => plans
            .where((p) =>
                !p.past &&
                (p.hostedByMe || p.myState != PlanJoinState.none))
            .toList(),
      };

  /// Wave 3 · phone-down entry (#13): from the plan card. Starts the
  /// session when none is running for this plan, then opens the
  /// session screen (which also handles the already-running and
  /// already-scored states).
  void _openPhoneDown(OpenPlan plan) {
    final store = Services.store;
    final active = store.activePhoneDown;
    if (active == null) store.startPhoneDown(plan.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PhoneDownScreen(plan: plan)),
    );
  }

  String _phoneDownLabel(OpenPlan plan) {
    final store = Services.store;
    final active = store.activePhoneDown;
    if (active != null && active.planId == plan.id) {
      return 'Phone-down running…';
    }
    final record = store.presenceRecordForPlan(plan.id);
    if (record != null) return 'Presence · ${record.score}';
    return 'Go phone-down';
  }

  /// Wave 3 · check-in sheet (#15): pick a state, name the trusted
  /// contact (persisted in prefs), preview the EXACT message — and the
  /// demo rail is stated on the sheet: nothing leaves the phone in
  /// this build.
  void _openCheckIn(OpenPlan plan) {
    final store = Services.store;
    final existing = store.checkInFor(plan.id);
    var selected = existing?.state ?? PlanCheckInState.checkedIn;
    final contactController = TextEditingController(
      text: Services.prefs.trustedContactName,
    );
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final preview = presence_logic.checkInMessageText(
            contactName: contactController.text,
            planTitle: plan.title,
            place: plan.place,
            state: selected,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Check in — ${plan.title}',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Your trusted contact gets one short message. That\'s '
                'the whole feature — no live location, ever.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('I\'m here'),
                    selected: selected == PlanCheckInState.checkedIn,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) => setSheetState(
                        () => selected = PlanCheckInState.checkedIn),
                  ),
                  ChoiceChip(
                    label: const Text('Running late'),
                    selected: selected == PlanCheckInState.runningLate,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) => setSheetState(
                        () => selected = PlanCheckInState.runningLate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                onChanged: (_) => setSheetState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Trusted contact (name)',
                  hintText: 'e.g. Mom, Alex, Priya…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Message preview',
                        style: Theme.of(ctx).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(preview,
                        style: Theme.of(ctx).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Demo build: this message is recorded on the plan and '
                'previewed here — nothing leaves your phone. In the '
                'live app it sends to your trusted contact.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              SparkButton(
                label: existing == null ? 'Check in' : 'Update check-in',
                icon: Icons.place_outlined,
                onPressed: () {
                  final record = store.setPlanCheckIn(
                    plan.id,
                    selected,
                    contactName: contactController.text,
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(record == null
                          ? 'Couldn\'t check in — you\'re not on this plan.'
                          : 'Checked in (demo — no message left this phone).'),
                    ),
                  );
                },
              ),
              if (existing != null)
                TextButton(
                  onPressed: () {
                    store.setPlanCheckIn(
                      plan.id,
                      PlanCheckInState.none,
                      contactName: contactController.text,
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Clear check-in'),
                ),
            ],
          );
        },
      ),
    ).whenComplete(contactController.dispose);
  }

  void _toggleJoin(OpenPlan plan) {
    final store = Services.store;
    final messenger = ScaffoldMessenger.of(context);
    if (plan.myState == PlanJoinState.none) {
      final ok = store.requestJoinPlan(plan.id);
      if (!ok) {
        messenger.showSnackBar(const SnackBar(
          content: Text('That plan just filled up — pick another one.'),
        ));
        return;
      }
      messenger.showSnackBar(SnackBar(
        content: Text(plan.instantJoin
            ? 'You\'re in — "${plan.title}". The plan chat opens in the live app.'
            : 'Request sent for "${plan.title}" — the host confirms joins.'),
      ));
    } else {
      final wasGoing = plan.myState == PlanJoinState.going;
      store.leavePlan(plan.id);
      messenger.showSnackBar(SnackBar(
        content: Text(wasGoing
            ? 'Left "${plan.title}" — your spot is released.'
            : 'Request cancelled for "${plan.title}".'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final plans = _visible(store.openPlans);
        final booking = store.tableBooking;
        final bookingNight = booking == null
            ? null
            : store.tableNightById(booking.nightId);
        return GlassScaffold(
          appBar: AppBar(title: const Text('Plans near you')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Text(
                'Real plans, verified people. Join one — or post yours and let the group form.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              // --- Cariño Tables banner ---
              GlassContainer(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const TablesScreen()),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_outlined,
                        size: 30, color: AppColors.sparkCoral),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cariño Tables',
                              style: theme.textTheme.titleMedium),
                          Text(
                            booking != null &&
                                    booking.status ==
                                        TableBookingStatus.confirmed &&
                                    bookingNight != null
                                ? 'You\'re booked · ${bookingNight.dateLabel} · '
                                    'venue reveals ${bookingNight.revealLabel}'
                                : 'A weekly dinner with five verified strangers. '
                                    'Venue + tablemates revealed on the day.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 12),
              // --- Wave 3.5 · Club & Event Tickets banner (T1) ---
              GlassContainer(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const TicketsScreen()),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined,
                        size: 30, color: AppColors.sparkCoral),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Club & event tickets',
                              style: theme.textTheme.titleMedium),
                          Text(
                            store.myActiveTickets.isEmpty
                                ? 'Club nights, live music, comedy, supper '
                                    'clubs — free and premium tickets.'
                                : 'You hold ${store.myActiveTickets.fold(0, (s, t) => s + t.quantity)} '
                                    'ticket${store.myActiveTickets.fold(0, (s, t) => s + t.quantity) == 1 ? '' : 's'} — '
                                    'see them in You → My Tickets.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 12),
              // --- Wave 4 · AI Concierge entry (A1) ---
              GlassContainer(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const ConciergeScreen()),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined,
                        size: 30, color: AppColors.sparkCoral),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Plan it for me',
                              style: theme.textTheme.titleMedium),
                          Text(
                            store.lastConciergeBooking != null
                                ? 'Last booked: ${store.lastConciergeBooking!.title} — '
                                    '${store.lastConciergeBooking!.actionSummary}'
                                : 'Say it in your own words — dinner, '
                                    'something calm, a night out — and the '
                                    'Concierge books the real thing.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),
              // --- Wave 4 · Outcome check-in prompt (A3) ---
              if (store.pendingOutcomePrompts().isNotEmpty) ...[
                const SizedBox(height: 12),
                GlassContainer(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const OutcomeCheckInScreen()),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fact_check_outlined,
                          size: 30, color: AppColors.sparkCoral),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('How did it go?',
                                style: theme.textTheme.titleMedium),
                            Text(
                              '${store.pendingOutcomePrompts().length} '
                              'past plan${store.pendingOutcomePrompts().length == 1 ? '' : 's'} '
                              'waiting for your check-in — did they happen?',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms),
              ],
              const SizedBox(height: 18),
              // --- Wave 3 · Decompress shelf (#12) ---
              Row(
                children: [
                  const Icon(Icons.spa_outlined,
                      size: 20, color: AppColors.sparkCoral),
                  const SizedBox(width: 8),
                  Text('Decompress', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Calm, bookable, offline. Low-key plans for when the '
                'week has been a lot — same verified people, slower '
                'everything.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 218,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: store.decompressPlans.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 252,
                    child: _DecompressCard(
                      plan: store.decompressPlans[i],
                      onJoinToggle: () =>
                          _toggleJoin(store.decompressPlans[i]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- Filters ---
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All plans'),
                    selected: _filter == _HubFilter.all,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) =>
                        setState(() => _filter = _HubFilter.all),
                  ),
                  ChoiceChip(
                    label: Text(
                        'Tonight · ${store.tonightPlans.length}'),
                    selected: _filter == _HubFilter.tonight,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) =>
                        setState(() => _filter = _HubFilter.tonight),
                  ),
                  ChoiceChip(
                    label: const Text('Mine'),
                    selected: _filter == _HubFilter.mine,
                    selectedColor: AppColors.emberCrimson,
                    onSelected: (_) =>
                        setState(() => _filter = _HubFilter.mine),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (plans.isEmpty)
                GlassContainer(
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 34),
                      const SizedBox(height: 10),
                      Text(
                        _filter == _HubFilter.tonight
                            ? 'Nothing left tonight'
                            : 'No plans here yet',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _filter == _HubFilter.tonight
                            ? 'Tonight\'s plans are full or done — tomorrow\'s board is already filling. Or start tonight\'s next one yourself.'
                            : 'Be the first to post one — plans here are how strangers become your people.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (var i = 0; i < plans.length; i++) ...[
                PlanCard(
                  plan: plans[i],
                  onJoinToggle: () => _toggleJoin(plans[i]),
                  // Wave 3 · check-in + phone-down ride the same card,
                  // only for plans I'm going to (#15 / #13).
                  onCheckIn: plans[i].myState == PlanJoinState.going
                      ? () => _openCheckIn(plans[i])
                      : null,
                  checkInState: store.checkInFor(plans[i].id)?.state ??
                      PlanCheckInState.none,
                  onPhoneDown: plans[i].myState == PlanJoinState.going
                      ? () => _openPhoneDown(plans[i])
                      : null,
                  phoneDownLabel: _phoneDownLabel(plans[i]),
                  // Wave 2 · a plan I'm part of can become a PrivateCircle.
                  onKeepAsCircle: store.canConvertPlanToCircle(plans[i])
                      ? () {
                          final circle =
                              store.convertPlanToCircle(plans[i].id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(circle == null
                                  ? 'That plan already became a PrivateCircle.'
                                  : 'PrivateCircle created: "${circle.name}" — '
                                      'find it under Your Circles in Connect.'),
                            ),
                          );
                        }
                      : null,
                ).animate().fadeIn(
                      delay: (60 * i).ms,
                      duration: 300.ms,
                    ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              SparkButton(
                label: 'Create a plan',
                icon: Icons.add_circle_outline,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const CreatePlanScreen()),
                ),
              ),
              const SizedBox(height: 12),
              // --- Wave 3 · Micro-Hosts entry (#14) ---
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.house_outlined,
                            size: 20, color: AppColors.sparkCoral),
                        const SizedBox(width: 8),
                        Text('Hosting on Cariño',
                            style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          store.hostTierLabel('me'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.sparkCoral),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.hostedPlanCount('me') == 0
                          ? 'You haven\'t hosted yet. Post a plan and the '
                              'Host badge lands on your profile the moment '
                              'it\'s live — standing grows with every plan '
                              'you host.'
                          : 'You\'ve hosted ${store.hostedPlanCount('me')} '
                              'plan${store.hostedPlanCount('me') == 1 ? '' : 's'} — '
                              'the Host badge is on your profile. Standing '
                              'grows with every plan you host.',
                      style: theme.textTheme.bodySmall,
                    ),
                    // Wave 4 · Outcome Graph (A3): once guests have
                    // checked in on my plans, the outcome line joins
                    // the count — computed from their records only.
                    if (store.hostRecordedCount('me') > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        store.hostOutcomeLine('me'),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.sparkCoral),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Guest check-ins ("did it happen?") feed this '
                      'standing — nothing is rated before it\'s real.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Plans are public-place, verified-members-only. Hosts see '
                'join requests; nobody sees anyone\'s address or live location.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
