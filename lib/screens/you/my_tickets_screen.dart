import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/ticket.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../connect/ticket_detail_screen.dart';

/// Wave 3.5 · My Tickets (MASTER-BUILD-PLAN T1) — every ticket the
/// member holds, in one place: night, tier, quantity, status, and
/// the door pass. Check-in happens HERE, from the ticket (demo rail:
/// the live app scans the venue's door code — the state change is
/// the mechanic). A checked-in ticket is final: it can't be
/// cancelled, because you were in the room.
class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final tickets = store.myTickets;
        return GlassScaffold(
          appBar: AppBar(title: const Text('My Tickets')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              if (tickets.isEmpty)
                GlassContainer(
                  child: Column(
                    children: [
                      const Icon(Icons.confirmation_number_outlined,
                          size: 34),
                      const SizedBox(height: 10),
                      Text('No tickets yet',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Club nights, live music, comedy, supper clubs '
                        '— when you claim or buy a ticket it lands here '
                        'with your door pass.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < tickets.length; i++) ...[
                  _ticketCard(context, tickets[i])
                      .animate()
                      .fadeIn(delay: (50 * i).ms, duration: 300.ms),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 4),
              Text(
                'Passes are demo visuals in this build — live passes '
                'carry a signed code the door scans. The ticket, the '
                'states and the door list are real.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ticketCard(BuildContext context, EventTicket ticket) {
    final theme = Theme.of(context);
    final store = Services.store;
    final night = store.clubNightById(ticket.nightId);
    if (night == null) return const SizedBox.shrink();
    final cancelled = ticket.status == EventTicketStatus.cancelled;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(night.title, style: theme.textTheme.titleMedium),
                    Text(
                      '${night.venueName} · ${night.areaLabel}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${night.dateLabel} · ${night.timeLabel}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _statusChip(context, ticket.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${ticket.tier.label} · ${ticket.quantity} '
            'ticket${ticket.quantity == 1 ? '' : 's'} · '
            '${ticket.totalPrice == 0 ? 'Free' : '\$${ticket.totalPrice} total'}'
            '${night.seller == TicketSeller.partner ? ' · via partner' : ''}',
            style: theme.textTheme.bodyMedium,
          ),
          if (!cancelled) ...[
            const SizedBox(height: 12),
            // --- The door pass (demo visual, honestly labelled). ---
            Row(
              children: [
                const _DemoPassVisual(),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ticket.status == EventTicketStatus.checkedIn
                        ? 'Checked in — you\'re on the door list as arrived. Enjoy the night.'
                        : ticket.status == EventTicketStatus.held
                            ? 'Held — finish checkout on the night page to make this a real pass.'
                            : 'Your door pass. Show it at ${night.venueName}; '
                                'the door checks your verified ID against the list.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ticket.status == EventTicketStatus.confirmed)
              SparkButton(
                label: 'Check in at the door (demo)',
                icon: Icons.qr_code_scanner_outlined,
                onPressed: () {
                  final ok = store.checkInEventTicket(ticket.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Checked in (demo) — the door list now shows you as arrived.'
                          : 'That ticket can\'t check in right now.'),
                    ),
                  );
                },
              ),
            if (ticket.status == EventTicketStatus.held)
              SparkButton(
                label: 'Finish checkout',
                icon: Icons.lock_clock_outlined,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TicketDetailScreen(night: night),
                  ),
                ),
              ),
            if (ticket.status == EventTicketStatus.held ||
                ticket.status == EventTicketStatus.confirmed)
              TextButton(
                onPressed: () {
                  final ok = store.cancelEventTicket(ticket.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Ticket cancelled — the spot is released for someone else.'
                          : 'That ticket can no longer be cancelled.'),
                    ),
                  );
                },
                child: Text(ticket.tier == TicketTier.free
                    ? 'Release ticket'
                    : 'Cancel ticket (demo refund)'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, EventTicketStatus status) {
    final (label, icon) = switch (status) {
      EventTicketStatus.held => ('Held', Icons.lock_clock_outlined),
      EventTicketStatus.confirmed => ('Confirmed', Icons.check_circle_outline),
      EventTicketStatus.checkedIn => ('Checked in', Icons.how_to_reg_outlined),
      EventTicketStatus.cancelled => ('Cancelled', Icons.cancel_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.emberCrimson.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.sparkCoral),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.sparkCoral),
          ),
        ],
      ),
    );
  }
}

/// A QR-STYLE placeholder — a deterministic block pattern, NOT a real
/// code. Labelled as a demo pass wherever it renders; the live pass
/// carries a signed payload the door verifies.
class _DemoPassVisual extends StatelessWidget {
  const _DemoPassVisual();

  @override
  Widget build(BuildContext context) {
    // Fixed pattern (finder squares in three corners, block noise in
    // the middle) — drawn from constants so it can never be mistaken
    // for scanned data.
    const pattern = <String>[
      '1111111010111',
      '1000101001010',
      '1011101110101',
      '1011101001011',
      '1011101101010',
      '1000101010101',
      '1111111011101',
      '0000000101010',
      '1101011100011',
      '0101100101010',
      '1010111011101',
      '0101010001010',
      '1110101101011',
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.warmIvory,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (final row in pattern)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final cell in row.split(''))
                  Container(
                    width: 4,
                    height: 4,
                    color: cell == '1'
                        ? AppColors.midnight
                        : AppColors.warmIvory,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
