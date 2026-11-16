import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/member.dart';
import '../models/plan.dart';
import '../models/presence.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'spark_button.dart';

/// Wave 1 · one open group plan as a card (Post→Plan, CROWD-FEATURES #9).
///
/// Renders the plan's REAL state from the store: host, attendee stack,
/// spots left, and the signed-in member's join state as the action —
/// Join (instant), Request to join (host approves), Requested / You're
/// in (tap again to undo), Full, or You're hosting. The button never
/// claims a state the store doesn't hold.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onJoinToggle,
    this.onKeepAsCircle,
    this.onCheckIn,
    this.checkInState = PlanCheckInState.none,
    this.onPhoneDown,
    this.phoneDownLabel,
  });

  final OpenPlan plan;

  /// Called when the member taps the join-state action. The parent owns
  /// the store call + feedback; the card is a pure render of [plan].
  final VoidCallback onJoinToggle;

  /// Wave 2 · "Keep this group as a circle" (CROWD-FEATURES #5): parents
  /// pass this only when the store says the plan can convert (member is
  /// hosting/going, not yet a circle) — null hides the action entirely.
  final VoidCallback? onKeepAsCircle;

  /// Wave 3 · Check-In Safety (CROWD-FEATURES #15): parents pass this
  /// only for plans the member is going to; null hides the action.
  final VoidCallback? onCheckIn;

  /// The member's current check-in state for this plan, from the store
  /// — the button label and chip render from it, never from local state.
  final PlanCheckInState checkInState;

  /// Wave 3 · Phone-Down Mode (CROWD-FEATURES #13): opens the
  /// phone-down flow for this plan; null hides the action.
  final VoidCallback? onPhoneDown;

  /// Label for the phone-down action, derived by the parent from store
  /// state: 'Go phone-down' · 'Phone-down running…' · 'Presence · 73'.
  final String? phoneDownLabel;

  Member get _host => plan.hostedByMe
      ? MockData.currentUser
      : MockData.memberById(plan.hostId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(_host.photoAsset),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.hostedByMe
                          ? 'Hosted by you'
                          : 'Hosted by ${_host.firstName}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(plan.title, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              if (plan.tonight)
                const Chip(
                  avatar: Icon(Icons.nightlight_outlined, size: 13),
                  label: Text('Tonight'),
                  backgroundColor: AppColors.emberCrimson,
                  labelStyle:
                      TextStyle(color: AppColors.warmIvory, fontSize: 11),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              if (plan.decompress) ...[
                if (plan.tonight) const SizedBox(width: 6),
                Chip(
                  avatar: const Icon(Icons.spa_outlined, size: 13),
                  label: const Text('Decompress'),
                  backgroundColor: theme.brightness == Brightness.dark
                      ? AppColors.plumCharcoal
                      : AppColors.porcelainDeep,
                  labelStyle: TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.softRose
                          : AppColors.midnight,
                      fontSize: 11),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.place_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 5),
              Expanded(child: Text(plan.place, style: theme.textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.schedule_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 5),
              Text(plan.timeLabel, style: theme.textTheme.bodyMedium),
              const SizedBox(width: 12),
              Icon(Icons.group_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 5),
              Text(
                plan.isFull
                    ? 'Full · ${plan.groupSize} going'
                    : '${plan.attendeeIds.length}/${plan.groupSize} · '
                        '${plan.spotsLeft} spot${plan.spotsLeft == 1 ? '' : 's'} left',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          if (plan.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(plan.note, style: theme.textTheme.bodySmall),
          ],
          if (plan.sourceLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              plan.sourceLabel!,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          // Attendee stack — real ids from the plan, host first.
          Row(
            children: [
              SizedBox(
                height: 30,
                width: 30 + (plan.attendeeIds.length.clamp(1, 5) - 1) * 22.0,
                child: Stack(
                  children: [
                    for (var i = 0; i < plan.attendeeIds.length && i < 5; i++)
                      Positioned(
                        left: i * 22.0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: theme.colorScheme.surface,
                          backgroundImage: AssetImage(
                            plan.attendeeIds[i] == 'me'
                                ? MockData.currentUser.photoAsset
                                : MockData.memberById(plan.attendeeIds[i])
                                    .photoAsset,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.hostedByMe
                      ? 'You\'re hosting this one'
                      : switch (plan.myState) {
                          PlanJoinState.going => 'You\'re in',
                          PlanJoinState.requested =>
                            'Requested — waiting on the host',
                          PlanJoinState.none => plan.instantJoin
                              ? 'Open to verified members'
                              : 'Host approves joins',
                        },
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (!plan.hostedByMe) ...[
            const SizedBox(height: 10),
            _action(context),
          ],
          // Wave 3 · the "you're in" row (#15 check-in, #13 phone-down):
          // rendered only when the parent wired the actions (plans the
          // member is going to). Both labels come from store state.
          if (plan.myState == PlanJoinState.going &&
              (onCheckIn != null || onPhoneDown != null)) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                if (onCheckIn != null)
                  TextButton.icon(
                    icon: Icon(
                      checkInState == PlanCheckInState.none
                          ? Icons.place_outlined
                          : Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.emberCrimson,
                    ),
                    label: Text(
                      switch (checkInState) {
                        PlanCheckInState.none => 'Check in',
                        PlanCheckInState.checkedIn => 'Checked in ✓',
                        PlanCheckInState.runningLate => 'Running late',
                      },
                      style: const TextStyle(
                          color: AppColors.emberCrimson, fontSize: 12.5),
                    ),
                    style: _miniButtonStyle,
                    onPressed: onCheckIn,
                  ),
                if (onPhoneDown != null)
                  TextButton.icon(
                    icon: const Icon(Icons.phone_android_outlined,
                        size: 16, color: AppColors.emberCrimson),
                    label: Text(
                      phoneDownLabel ?? 'Go phone-down',
                      style: const TextStyle(
                          color: AppColors.emberCrimson, fontSize: 12.5),
                    ),
                    style: _miniButtonStyle,
                    onPressed: onPhoneDown,
                  ),
              ],
            ),
          ],
          if (onKeepAsCircle != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.groups_outlined,
                    size: 16, color: AppColors.emberCrimson),
                label: const Text('Keep this group as a circle',
                    style: TextStyle(
                        color: AppColors.emberCrimson, fontSize: 12.5)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onKeepAsCircle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static final ButtonStyle _miniButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    minimumSize: const Size(0, 30),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Widget _action(BuildContext context) {
    return switch (plan.myState) {
      PlanJoinState.going => SparkButton(
          label: 'You\'re in — tap to leave',
          secondary: true,
          onPressed: onJoinToggle,
        ),
      PlanJoinState.requested => SparkButton(
          label: 'Requested — tap to cancel',
          secondary: true,
          onPressed: onJoinToggle,
        ),
      PlanJoinState.none => SparkButton(
          label: plan.isFull
              ? 'Plan full'
              : (plan.instantJoin ? 'Join plan' : 'Request to join'),
          icon: plan.isFull ? null : Icons.group_add_outlined,
          onPressed: plan.isFull ? null : onJoinToggle,
        ),
    };
  }
}
