import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/mock_data.dart';
import '../../models/plan.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import 'plans_hub_screen.dart';

/// Wave 1 · Cariño Tables (CROWD-FEATURES #11) — the weekly verified-only
/// group dinner. The mechanic is the category's proven one (commitment +
/// late reveal): book a seat → we seat you at a table of six → the VENUE
/// and your TABLEMATES are revealed only on the day, shortly before
/// dinner. Nobody browses people; everybody shows up.
///
/// Booking states are REAL store state (hold → confirmed → cancel), the
/// checkout is an honestly-labelled DEMO (no card, no reservation), and
/// the no-show policy is enforced by the store: one no-show warns, a
/// second bans — see [AppStore.recordTableNoShow].
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  String? _selectedNightId;
  int _seats = 1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final booking = store.tableBooking;
        return GlassScaffold(
          appBar: AppBar(title: const Text('Cariño Tables')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              if (booking != null &&
                  booking.status == TableBookingStatus.confirmed)
                _confirmed(context, booking)
              else if (booking != null)
                _checkout(context, booking)
              else
                _pick(context),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------ pick step

  Widget _pick(BuildContext context) {
    final theme = Theme.of(context);
    final store = Services.store;
    final banned = store.tablesStanding == TablesStanding.banned;
    final selected = _selectedNightId == null
        ? null
        : store.tableNightById(_selectedNightId!);
    final selectedSoldOut =
        selected != null && store.tableSeatsLeft(selected) <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'One dinner a week. Six verified people, one table. You don\'t '
          'pick the table — that\'s the point.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How Tables works', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              const _HowStep(
                n: '1',
                text: 'Book a seat for a night (\$17–35 — matching, the '
                    'reserved table and hosting; the meal is paid at the '
                    'restaurant).',
              ),
              const _HowStep(
                n: '2',
                text: 'We seat you with five other verified members — '
                    'matched on the night\'s vibe, not browsed by you.',
              ),
              const _HowStep(
                n: '3',
                text: 'Venue and tablemates are REVEALED ON THE DAY, a '
                    'couple of hours before dinner. Until then it\'s a '
                    'neighbourhood and a promise.',
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: 14),
        if (banned)
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.block_outlined,
                        color: AppColors.sparkCoral),
                    const SizedBox(width: 8),
                    Text('Tables access ended',
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Two no-shows put a ban on this account (see the policy '
                  'below). Five other people plan their evening around '
                  'every seat — the rule is the product.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
        else ...[
          if (store.tablesStanding == TablesStanding.warned) ...[
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: AppColors.sparkCoral, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No-show warning on file — one more missed dinner ends Tables access.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text('Pick your night', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final night in MockData.tableNights) ...[
            _nightCard(context, night),
            const SizedBox(height: 10),
          ],
          if (selected != null && !selectedSoldOut) ...[
            Row(
              children: [
                Text('Seats', style: theme.textTheme.titleMedium),
                const SizedBox(width: 6),
                Text('(bring one guest max)',
                    style: theme.textTheme.bodySmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      _seats > 1 ? () => setState(() => _seats--) : null,
                ),
                Text('$_seats', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _seats < 2 &&
                          _seats < store.tableSeatsLeft(selected)
                      ? () => setState(() => _seats++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          SparkButton(
            label: selected == null
                ? 'Pick a night to continue'
                : selectedSoldOut
                    ? '${selected.dayLabel} is sold out'
                    : 'Continue · ${selected.dateLabel} · '
                        '\$${selected.seatPrice * _seats}',
            icon: Icons.restaurant_outlined,
            onPressed: selected == null || selectedSoldOut
                ? null
                : () {
                    final held =
                        store.holdTableSeat(selected, seats: _seats);
                    if (held == null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Those seats just went — pick another night.'),
                        ),
                      );
                    }
                  },
          ),
        ],
        const SizedBox(height: 16),
        _policyCard(context),
      ],
    );
  }

  Widget _nightCard(BuildContext context, TableNight night) {
    final theme = Theme.of(context);
    final store = Services.store;
    final left = store.tableSeatsLeft(night);
    final soldOut = left <= 0;
    final isSelected = _selectedNightId == night.id;
    return GlassContainer(
      onTap: soldOut
          ? null
          : () => setState(() {
                _selectedNightId = night.id;
                if (_seats > left) _seats = left.clamp(1, 2);
              }),
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: soldOut ? AppColors.softRose : AppColors.sparkCoral,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${night.dayLabel} · ${night.dateLabel}',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${night.areaLabel} · ${night.vibeLabel} · table of ${TableNight.tableSize}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  soldOut
                      ? 'Sold out — every seat taken'
                      : '$left of ${night.capacity} seats left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: soldOut ? AppColors.softRose : AppColors.sparkCoral,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${night.seatPrice}/seat',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppColors.sparkCoral),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------- checkout step

  Widget _checkout(BuildContext context, TableBooking booking) {
    final theme = Theme.of(context);
    final store = Services.store;
    final night = store.tableNightById(booking.nightId)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_clock_outlined,
                      color: AppColors.sparkCoral),
                  const SizedBox(width: 8),
                  Text('Seat held', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              _row(context, 'Night', '${night.dayLabel} · ${night.dateLabel}'),
              _row(context, 'Area', '${night.areaLabel} (venue reveals '
                  '${night.revealLabel})'),
              _row(context, 'Table', 'Table of ${TableNight.tableSize} · '
                  'verified members only'),
              _row(context, 'Seats', '${booking.seats} × \$${night.seatPrice}'),
              const Divider(height: 20),
              _row(context, 'Total', '\$${booking.totalPrice}',
                  bold: true),
              const SizedBox(height: 6),
              Text(
                'The seat price covers matching, the reserved table and '
                'hosting. Dinner itself is paid at the restaurant.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 14),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.sparkCoral),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo checkout — no card is charged and no real '
                  'reservation is made in this build. In production this '
                  'step is a real payment, and the restaurant gets a real '
                  'booking for your table.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SparkButton(
          label: 'Pay \$${booking.totalPrice} · confirm seat (demo)',
          icon: Icons.check_circle_outline,
          onPressed: () {
            Services.store.confirmTableBooking();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Booked (demo) — see you ${night.dayLabel}. Watch for the reveal on the day.'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Services.store.cancelTableBooking(),
          child: const Text('Release the hold instead'),
        ),
      ],
    );
  }

  // ------------------------------------------------------- confirmed step

  Widget _confirmed(BuildContext context, TableBooking booking) {
    final theme = Theme.of(context);
    final store = Services.store;
    final night = store.tableNightById(booking.nightId)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          child: Column(
            children: [
              const Icon(Icons.check_circle,
                  size: 44, color: AppColors.sparkCoral),
              const SizedBox(height: 10),
              Text('You\'re booked for ${night.dayLabel}',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                '${night.dateLabel} · 19:00 · ${night.areaLabel} · '
                '${booking.seats} seat${booking.seats == 1 ? '' : 's'} · '
                'paid (demo)',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms).scale(
              begin: const Offset(0.96, 0.96),
              end: const Offset(1, 1),
              duration: 350.ms,
            ),
        const SizedBox(height: 14),
        // --- The late reveal: the state IS the feature. ---
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: AppColors.sparkCoral),
                  const SizedBox(width: 8),
                  Text('Revealed on the day',
                      style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Unlocks ${night.revealLabel} — a couple of hours before '
                'dinner. Not before. The not-knowing is what makes '
                'everyone at the table equal.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _row(context, 'Venue',
                  'A restaurant in ${night.areaLabel} — name hidden until reveal'),
              const SizedBox(height: 10),
              Text('Your tablemates', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < TableNight.tableSize - 1; i++) ...[
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.plumCharcoal,
                      child: Icon(Icons.person_outline,
                          size: 18, color: AppColors.softRose),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Expanded(
                    child: Text(
                      'Five verified members — names and faces arrive with the venue.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nobody can message the table before the reveal — no '
                'pre-screening people, no picking favourites. Just show up.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SparkButton(
          label: 'See plans near you',
          secondary: true,
          icon: Icons.event_outlined,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlansHubScreen()),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () {
            Services.store.cancelTableBooking();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Booking cancelled (demo) — your seat is released to the waitlist.'),
              ),
            );
          },
          child: const Text('Cancel booking (demo)'),
        ),
        const SizedBox(height: 8),
        _policyCard(context),
      ],
    );
  }

  // -------------------------------------------------------------- shared

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
  }

  Widget _policyCard(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_outlined,
                  size: 18, color: AppColors.sparkCoral),
              const SizedBox(width: 8),
              Text('The no-show policy', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Five people plan their evening around your seat.\n'
            '· Can\'t make it? Cancel in the app up to 3 hours before — '
            'no penalty, ever.\n'
            '· One no-show = a warning on your account.\n'
            '· A second no-show = banned from Tables.\n'
            'Running late happens — message the table from the reveal '
            'screen and it never counts as a no-show.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  const _HowStep({required this.n, required this.text});
  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.emberCrimson,
            child: Text(n,
                style: const TextStyle(
                    color: AppColors.warmIvory,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
