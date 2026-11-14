import 'package:flutter/material.dart';
import '../models/platform.dart';
import '../services/services.dart';
import 'glass_card.dart';
import 'spark_button.dart';

class PlanSplitCard extends StatefulWidget {
  const PlanSplitCard(
      {super.key,
      required this.planKey,
      required this.otherId,
      required this.otherName});
  final String planKey;
  final String otherId;
  final String otherName;
  @override
  State<PlanSplitCard> createState() => _PlanSplitCardState();
}

class _PlanSplitCardState extends State<PlanSplitCard> {
  final _amount = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final split = Services.prefs.planSplits[widget.planKey];
    return GlassContainer(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Split the cost', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      const Text(
          'Equal shares in USD. Personal records for this session only; no money is transferred or payment verified.'),
      if (split == null) ...[
        TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: 'Total cost (USD)',
                hintText: '24.50',
                errorText: _error)),
        const SizedBox(height: 10),
        SparkButton(
            label: 'Calculate shares',
            secondary: true,
            onPressed: () {
              final cents = parseCostCents(_amount.text);
              if (cents == null || cents <= 0) {
                setState(() => _error =
                    'Enter a positive amount with up to two decimals.');
                return;
              }
              setState(() {
                Services.prefs.planSplits[widget.planKey] = PlanSplit(
                    totalCents: cents, participants: ['me', widget.otherId]);
                _error = null;
              });
            }),
      ] else ...[
        const SizedBox(height: 10),
        Text('Total: ${formatCents(split.totalCents)}'),
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('You'),
            subtitle: Text(
                split.mySharePaid ? 'Marked paid by you' : 'Not marked paid'),
            trailing: Text(formatCents(split.amounts.first))),
        ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(widget.otherName),
            subtitle: const Text('Payment not verified'),
            trailing: Text(formatCents(split.amounts[1]))),
        SparkButton(
            label:
                split.mySharePaid ? 'Undo my paid mark' : 'Mark my share paid',
            secondary: true,
            onPressed: () =>
                setState(() => split.mySharePaid = !split.mySharePaid)),
        TextButton(
            onPressed: () => setState(() {
                  Services.prefs.planSplits.remove(widget.planKey);
                  _amount.text = (split.totalCents / 100).toStringAsFixed(2);
                }),
            child: const Text('Edit total (resets paid mark)')),
      ],
    ]));
  }
}
