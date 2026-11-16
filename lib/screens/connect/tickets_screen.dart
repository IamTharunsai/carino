import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/mock_data.dart';
import '../../models/ticket.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'ticket_detail_screen.dart';

/// Wave 3.5 · Club & Event Tickets browse (MASTER-BUILD-PLAN T1).
///
/// Every kind of club night, browsed by venue — the opposite of
/// Tables' late reveal: here the room IS the draw. Nights sold by
/// Cariño carry our ticketing (transparent service fee at checkout);
/// partner nights are affiliate listings and say so on the card
/// ("via partner" — no Cariño fee, ever). Sold-out nights render
/// sold out; they don't disappear.
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        return GlassScaffold(
          appBar: AppBar(title: const Text('Club & event tickets')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Text(
                'Club nights with verified people in the room. Free '
                'tickets are real reservations; premium buys the '
                'perks the venue lists — nothing more, nothing hidden.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < MockData.clubNights.length; i++) ...[
                _nightCard(context, MockData.clubNights[i])
                    .animate()
                    .fadeIn(delay: (50 * i).ms, duration: 300.ms),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              Text(
                'Nights marked "via partner" are listed for discovery — '
                'the partner venue runs its own door and its own '
                'ticketing, and Cariño takes no service fee on them.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _nightCard(BuildContext context, ClubNight night) {
    final theme = Theme.of(context);
    final store = Services.store;
    final left = store.eventSeatsLeft(night);
    final soldOut = left <= 0;
    final mine =
        store.myTicketsForNight(night.id).where((t) => t.isActive).toList();
    return GlassContainer(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TicketDetailScreen(night: night),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.confirmation_number_outlined,
              size: 28, color: AppColors.sparkCoral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  night.categoryLabel.toUpperCase(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.sparkCoral),
                ),
                const SizedBox(height: 2),
                Text(night.title, style: theme.textTheme.titleMedium),
                Text(
                  '${night.venueName} · ${night.areaLabel}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${night.dateLabel} · ${night.timeLabel} · ${night.vibeLabel}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  soldOut
                      ? 'Sold out — every ticket taken'
                      : '$left of ${night.capacity} tickets left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: soldOut ? AppColors.softRose : AppColors.sparkCoral,
                  ),
                ),
                if (mine.isNotEmpty)
                  Text(
                    'You hold ${mine.fold(0, (s, t) => s + t.quantity)} '
                    'ticket${mine.fold(0, (s, t) => s + t.quantity) == 1 ? '' : 's'} '
                    'for this night',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.sparkCoral),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (night.seller == TicketSeller.partner)
                const _SellerChip(label: 'Via partner')
              else
                const _SellerChip(label: 'Cariño night'),
              const SizedBox(height: 6),
              Text(
                night.offersPremium
                    ? 'Free · \$${night.premiumPrice} premium'
                    : 'Free entry',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellerChip extends StatelessWidget {
  const _SellerChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.emberCrimson.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.sparkCoral),
      ),
    );
  }
}
