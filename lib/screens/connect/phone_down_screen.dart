import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../models/presence.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// Wave 3 · Phone-Down Mode (CROWD-FEATURES #13).
///
/// Started from a plan the member is going to. The session is a REAL
/// timer over a REAL store record: start stamps the clock, End computes
/// the Presence Score from actual elapsed minutes vs the plan's real
/// length and group size, and the record lands in Presence (You tab).
///
/// DEMO LABEL, stated on screen: the OS-level app lock (Screen Time /
/// Digital Wellbeing) that blocks distracting apps during a session is
/// a hosting-phase integration. This build times and scores the session
/// for real; it does not pretend to lock anything.
class PhoneDownScreen extends StatefulWidget {
  const PhoneDownScreen({super.key, required this.plan});

  final OpenPlan plan;

  @override
  State<PhoneDownScreen> createState() => _PhoneDownScreenState();
}

class _PhoneDownScreenState extends State<PhoneDownScreen> {
  Timer? _ticker;
  PresenceRecord? _finished;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _elapsedLabel(PhoneDownSession session) {
    final seconds =
        DateTime.now().difference(session.startedAt).inSeconds;
    final s = seconds < 0 ? 0 : seconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Services.store,
      builder: (context, _) {
        final store = Services.store;
        final plan = store.planById(widget.plan.id) ?? widget.plan;
        final session = store.activePhoneDown;
        final mineHere = session != null && session.planId == plan.id;
        final record = _finished ?? store.presenceRecordForPlan(plan.id);
        return GlassScaffold(
          appBar: AppBar(title: const Text('Phone-Down Mode')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_android_outlined,
                            color: AppColors.sparkCoral),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(plan.title, style: text.titleLarge),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${plan.place} · ${plan.timeLabel} · '
                      '${plan.attendeeIds.length} people · '
                      '${plan.durationMinutes} min plan',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Phone-Down means: phone away for the plan, attention '
                      'on the people. End the session when the plan wraps '
                      'and your Presence Score is computed from the real '
                      'minutes — and saved under You → Presence.',
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (mineHere) ...[
                GlassContainer(
                  child: Column(
                    children: [
                      Text('Phone down for',
                          style: text.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        _elapsedLabel(session),
                        style: text.displaySmall?.copyWith(
                          color: AppColors.sparkCoral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Session running. In the live app your distracting '
                        'apps stay locked until you end this — demo build: '
                        'the timer and score are real, the OS lock arrives '
                        'at hosting.',
                        style: text.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SparkButton(
                  label: 'End session — score my presence',
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    final result = store.endPhoneDown();
                    if (result != null) {
                      setState(() => _finished = result);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SparkButton(
                  label: 'Discard session',
                  secondary: true,
                  onPressed: () {
                    store.cancelPhoneDown();
                    Navigator.of(context).pop();
                  },
                ),
              ] else if (session != null) ...[
                GlassContainer(
                  child: Text(
                    'A phone-down session is already running for another '
                    'plan — one at a time, because you\'re only ever in '
                    'one place. End it there first.',
                    style: text.bodyMedium,
                  ),
                ),
              ] else if (record != null) ...[
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.spa_outlined,
                              color: AppColors.sparkCoral),
                          const SizedBox(width: 8),
                          Text('Your Presence Score',
                              style: text.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          '${record.score}',
                          style: text.displayMedium?.copyWith(
                            color: AppColors.sparkCoral,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phone down ${record.phoneDownMinutes} of '
                        '${record.planMinutes} min · with '
                        '${record.groupSize} '
                        '${record.groupSize == 1 ? 'person' : 'people'} · '
                        '${record.dateLabel}. The score is coverage (85) + '
                        'company (15) — re-derive it any time from these '
                        'numbers; nothing else feeds it.',
                        style: text.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SparkButton(
                  label: 'Go phone-down again',
                  icon: Icons.phone_android_outlined,
                  secondary: true,
                  onPressed: () => store.startPhoneDown(plan.id),
                ),
              ] else ...[
                SparkButton(
                  label: 'Go phone-down',
                  icon: Icons.phone_android_outlined,
                  onPressed: () => store.startPhoneDown(plan.id),
                ),
                const SizedBox(height: 8),
                Text(
                  'Starts the session timer now. Demo build: the timer '
                  'and score are real; the OS-level app lock arrives at '
                  'hosting and will be labelled the same way.',
                  style: text.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
