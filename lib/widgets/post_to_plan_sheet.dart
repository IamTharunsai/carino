import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/social.dart';
import '../services/services.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'spark_button.dart';

/// Post → Plan: any post becomes a real plan in two taps — what, when, who.
/// Public place types only; invites go to a circle or chosen friends.
/// The created plan lands in Plans → "Your plans".
Future<void> showPostToPlanSheet(BuildContext context, {String idea = ''}) {
  final what = TextEditingController(text: idea);
  var when = 'Tonight · 20:00';
  var who = Circle.friends;
  const times = ['Tonight · 20:00', 'Tomorrow · 19:00', 'Sat · 14:00', 'Sun · 12:00'];
  return showGlassSheet<void>(
    context,
    child: StatefulBuilder(
      builder: (ctx, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Make it a plan', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: what,
            decoration: const InputDecoration(labelText: 'What (public place or activity)'),
          ),
          const SizedBox(height: 12),
          Text('When', style: Theme.of(ctx).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in times)
                ChoiceChip(
                  label: Text(t),
                  selected: when == t,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setSheet(() => when = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Who', style: Theme.of(ctx).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in [Circle.inner, Circle.friends, Circle.everyone])
                ChoiceChip(
                  label: Text(c.label),
                  selected: who == c,
                  selectedColor: AppColors.emberCrimson,
                  onSelected: (_) => setSheet(() => who = c),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_inviteCount(who)} people will be invited. Nobody meets a stranger alone.',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          SparkButton(
            label: 'Post the plan',
            icon: Icons.event_available_outlined,
            onPressed: () {
              final w = what.text.trim();
              if (w.isEmpty) return;
              Services.prefs.myPlans.add('$w · $when · ${who.label}');
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Plan posted to ${who.label}. RSVPs land in Plans.')));
            },
          ),
        ],
      ),
    ),
  );
}

int _inviteCount(Circle c) => switch (c) {
      Circle.inner => Services.social.inCircle(Circle.inner).length,
      Circle.friends => Services.social.inCircle(Circle.inner).length +
          Services.social.inCircle(Circle.friends).length,
      _ => Services.social.inCircle(Circle.inner).length +
          Services.social.inCircle(Circle.friends).length +
          MockData.matches.length,
    };
