import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/ticket.dart';
import '../../services/services.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../you/my_tickets_screen.dart';

/// Wave 3.5 · One club night, end to end (MASTER-BUILD-PLAN T1):
/// pick a tier → see the FULL price before confirming → free claims
/// land instantly, premium holds a seat through an honestly-labelled
/// demo checkout → the ticket lives in You → My Tickets.
///
/// The money rules are the store's ([AppStore.ticketQuote]): our own
/// nights show a transparent service-fee line; partner nights are
/// affiliate listings and show NO fee line — the partner pays us,
/// the member doesn't.
class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.night});

  final ClubNight night;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  TicketTier? _tier;
  int _qty = 1;

  ClubNight get night => widget.night;

  TicketTier get _selectedTier =>
      _tier ??
      (night.offersFree ? TicketTier.free : TicketTier.premium);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        EventTicket? held;
        for (final t in store.myTicketsForNight(night.id)) {
          if (t.status == EventTicketStatus.held) {
            held = t;
            break;
          }
        }
        return GlassScaffold(
          appBar: AppBar(title: const Text('Tickets')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              _header(context),
              const SizedBox(height: 14),
              if (held != null)
                _checkout(context, held)
              else
                _order(context),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------- header

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final store = Services.store;
    final left = store.eventSeatsLeft(night);
    final soldOut = left <= 0;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            night.categoryLabel.toUpperCase(),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.sparkCoral),
          ),
          const SizedBox(height: 4),
          Text(night.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${night.venueName} · ${night.areaLabel}',
              style: theme.textTheme.titleMedium),
          Text(
            '${night.dateLabel} · doors ${night.timeLabel} · ${night.vibeLabel}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            soldOut
                ? 'Sold out — every ticket for this night is taken.'
                : '$left of ${night.capacity} tickets left',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: soldOut ? AppColors.softRose : AppColors.sparkCoral,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            night.seller == TicketSeller.partner
                ? 'Via partner — ${night.venueName} runs its own door and '
                    'ticketing; Cariño lists the night and takes no '
                    'service fee on it.'
                : 'A Cariño night — our ticketing, our door list, '
                    'verified members only.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ---------------------------------------------------------- order step

  Widget _order(BuildContext context) {
    final theme = Theme.of(context);
    final store = Services.store;
    final soldOut = store.eventNightSoldOut(night);
    final left = store.eventSeatsLeft(night);
    final tier = _selectedTier;
    final quote = store.ticketQuote(night, tier, _qty);
    final mine = store
        .myTicketsForNight(night.id)
        .where((t) =>
            t.status == EventTicketStatus.confirmed ||
            t.status == EventTicketStatus.checkedIn)
        .toList();
    final maxQty = left < AppStore.maxTicketsPerOrder
        ? (left < 1 ? 1 : left)
        : AppStore.maxTicketsPerOrder;
    if (_qty > maxQty) _qty = maxQty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mine.isNotEmpty) ...[
          GlassContainer(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.sparkCoral, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'re going — ${mine.fold(0, (s, t) => s + t.quantity)} '
                    'ticket${mine.fold(0, (s, t) => s + t.quantity) == 1 ? '' : 's'} '
                    'in My Tickets.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const MyTicketsScreen()),
                  ),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (night.offersFree) ...[
          _tierCard(
            context,
            tier: TicketTier.free,
            title: 'Free ticket',
            lines: const [
              'Entry on the door list, no payment.',
              'A claim is a promise — the room holds your spot.',
            ],
            priceLabel: '\$0',
          ),
          const SizedBox(height: 10),
        ],
        if (night.offersPremium) ...[
          _tierCard(
            context,
            tier: TicketTier.premium,
            title: 'Premium ticket',
            lines: [
              for (final perk in night.premiumPerks) '· $perk',
              if (night.premiumPerks.isEmpty) 'The venue\'s best entry.',
            ],
            priceLabel: '\$${night.premiumPrice}',
          ),
          const SizedBox(height: 10),
        ],
        // Quantity — one order, capped, never more than the room holds.
        Row(
          children: [
            Text('Tickets', style: theme.textTheme.titleMedium),
            const SizedBox(width: 6),
            Text('(max ${AppStore.maxTicketsPerOrder} per order)',
                style: theme.textTheme.bodySmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  _qty > 1 ? () => setState(() => _qty--) : null,
            ),
            Text('$_qty', style: theme.textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: !soldOut && _qty < maxQty
                  ? () => setState(() => _qty++)
                  : null,
            ),
          ],
        ),
        if (tier == TicketTier.premium && !soldOut) ...[
          GlassContainer(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _moneyRow(context, 'Tickets',
                    '${quote.quantity} × \$${quote.unitPrice}',
                    '\$${quote.subtotal}'),
                if (quote.hasFeeLine)
                  _moneyRow(context, 'Service fee',
                      '${quote.quantity} × \$${quote.serviceFeePerTicket}',
                      '\$${quote.feeTotal}')
                else if (night.seller == TicketSeller.partner)
                  _moneyRow(context, 'Service fee',
                      'via partner — none', '\$0'),
                const Divider(height: 16),
                _moneyRow(context, 'Total', '', '\$${quote.total}',
                    bold: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (tier == TicketTier.free && !soldOut) ...[
          GlassContainer(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rule_outlined,
                    size: 18, color: AppColors.sparkCoral),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Free tickets carry the same promise as paid ones: '
                    'can\'t make it, release the ticket here so someone '
                    'else can go. In the live app an unused free ticket '
                    'counts as a no-show against your standing — the '
                    'room planned around your spot.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SparkButton(
          label: soldOut
              ? 'Sold out'
              : tier == TicketTier.free
                  ? 'Claim $_qty free ticket${_qty == 1 ? '' : 's'}'
                  : 'Continue · \$${quote.total} total',
          icon: Icons.confirmation_number_outlined,
          onPressed: soldOut
              ? null
              : () {
                  if (tier == TicketTier.free) {
                    final ticket =
                        store.claimFreeTicket(night, quantity: _qty);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ticket == null
                            ? 'Those tickets just went — try another night.'
                            : 'Claimed — find it in You → My Tickets.'),
                      ),
                    );
                  } else {
                    final held =
                        store.holdPremiumTicket(night, quantity: _qty);
                    if (held == null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Those tickets just went — try another night.'),
                        ),
                      );
                    }
                  }
                },
        ),
      ],
    );
  }

  Widget _tierCard(
    BuildContext context, {
    required TicketTier tier,
    required String title,
    required List<String> lines,
    required String priceLabel,
  }) {
    final theme = Theme.of(context);
    final selected = _selectedTier == tier;
    return GlassContainer(
      onTap: () => setState(() => _tier = tier),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: AppColors.sparkCoral,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                for (final line in lines)
                  Text(line, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            priceLabel,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppColors.sparkCoral),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- checkout step

  Widget _checkout(BuildContext context, EventTicket held) {
    final theme = Theme.of(context);
    final store = Services.store;
    final quote =
        store.ticketQuote(night, TicketTier.premium, held.quantity);
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
                  Text('Tickets held', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              _moneyRow(context, 'Night', night.title, ''),
              _moneyRow(context, 'Venue',
                  '${night.venueName} · ${night.areaLabel}', ''),
              _moneyRow(context, 'When',
                  '${night.dateLabel} · ${night.timeLabel}', ''),
              _moneyRow(context, 'Tickets',
                  '${quote.quantity} × \$${quote.unitPrice}',
                  '\$${quote.subtotal}'),
              if (quote.hasFeeLine)
                _moneyRow(context, 'Service fee',
                    '${quote.quantity} × \$${quote.serviceFeePerTicket}',
                    '\$${quote.feeTotal}')
              else if (night.seller == TicketSeller.partner)
                _moneyRow(
                    context, 'Service fee', 'via partner — none', '\$0'),
              const Divider(height: 20),
              _moneyRow(context, 'Total', '', '\$${held.totalPrice}',
                  bold: true),
              const SizedBox(height: 6),
              Text(
                'The total above is the total — computed before you '
                'confirm, never re-priced after.',
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
                  night.seller == TicketSeller.partner
                      ? 'Demo checkout — no card is charged in this '
                          'build. In production a partner night is '
                          'completed on the partner\'s own ticketing '
                          'rail; Cariño never touches the money.'
                      : 'Demo checkout — no card is charged in this '
                          'build. In production this step is a real '
                          'payment through our ticketing rail, and the '
                          'venue gets a real door list with your name '
                          'on it.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SparkButton(
          label: 'Pay \$${held.totalPrice} · confirm tickets (demo)',
          icon: Icons.check_circle_outline,
          onPressed: () {
            Services.store.confirmEventTicket(held.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Tickets confirmed (demo) — find them in You → My Tickets.'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Services.store.cancelEventTicket(held.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hold released — the tickets are back on sale.'),
              ),
            );
          },
          child: const Text('Release the hold instead'),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- shared

  Widget _moneyRow(BuildContext context, String label, String detail,
      String amount,
      {bool bold = false}) {
    final theme = Theme.of(context);
    final style =
        bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: style)),
          Expanded(child: Text(detail, style: style)),
          Text(amount, style: style),
        ],
      ),
    );
  }
}
