import 'package:flutter/material.dart';
import '../models/sync.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// "How Aria texts" — a member's own texting-style answers and comfort
/// rules. Shows nothing that wasn't answered.
class TextingCard extends StatelessWidget {
  const TextingCard({
    super.key,
    required this.title,
    required this.style,
    required this.comfort,
  });

  final String title;
  final TextingStyle style;
  final ComfortRules comfort;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rules = comfortSummary(comfort);
    Widget tags(List<String> items, {IconData? icon}) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final i in items)
              Chip(
                avatar: icon == null ? null : Icon(icon, size: 14),
                label: Text(i),
                labelStyle: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                visualDensity: VisualDensity.compact,
              ),
          ],
        );
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.sparkCoral),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: 8),
          if (style.isEmpty && rules.isEmpty)
            Text('Not filled in yet.', style: text.bodySmall)
          else ...[
            if (style.labels.isNotEmpty) tags(style.labels),
            if (style.loves.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Topics I love', style: text.bodySmall),
              const SizedBox(height: 4),
              tags(style.loves, icon: Icons.favorite_border),
            ],
            if (style.avoid.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Please don\'t ask about', style: text.bodySmall),
              const SizedBox(height: 4),
              tags(style.avoid, icon: Icons.do_not_disturb_on_outlined),
            ],
            if (rules.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Comfort rules · Cariño keeps these for both of you',
                  style: text.bodySmall),
              const SizedBox(height: 4),
              tags(rules, icon: Icons.shield_outlined),
            ],
          ],
        ],
      ),
    );
  }
}

/// A calm "not yet" sheet used when a comfort rule holds something back.
Future<void> showComfortHold(BuildContext context, String reason, {VoidCallback? onPlan}) {
  return showGlassSheet<void>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.shield_outlined, size: 36, color: AppColors.sparkCoral),
        const SizedBox(height: 8),
        Text('Not yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(reason, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (onPlan != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPlan();
            },
            child: const Text('Suggest a plan instead'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Okay'),
        ),
      ],
    ),
  );
}
