import 'package:flutter/material.dart';
import '../models/member.dart';
import '../screens/you/report_confirmation_screen.dart';
import '../services/services.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Report + Block + Appeals (blueprint S-049 / S-050B / S-051 / S-052).
///
/// Reachable from EVERY surface that shows a person — profile detail, chat,
/// Moments, Spark call — and from the Trust & Safety Centre. NEVER paywalled,
/// and RemoteConfig can never hide or re-word these entries (see
/// RemoteConfigService hard limits). Safety actions are calm: no celebration
/// styling, no sound (steady haptic only).
///
/// REPORTING IS A STRUCTURED TREE (REA pattern, rea-patterns.md §5.3 —
/// Tinder ships `/v4/report/tree`, a reason tree, not a free-text box):
/// category -> specific reason -> optional detail. A tree routes cases to
/// the right Trust queue with the right evidence the first time.
///
/// APPEALS ARE FIRST-CLASS (REA §5.3 — `/v1/appeals`,
/// `/v1/case/warnings/acknowledge`): any member can appeal an enforcement
/// decision about THEIR OWN account, and acknowledge or appeal a warning.
/// The entry point below is linked from the Trust & Safety Centre and from
/// every enforcement notice (S-051).
class SafetyActions {
  SafetyActions._();

  static final SoundService _sound = SoundService();

  /// The structured report-reason tree: category -> specific reasons.
  /// Server-driven in production (the Trust team owns the taxonomy);
  /// this compiled copy is the fallback and must stay in sync.
  static const Map<String, List<String>> reportTree = {
    'Fake or misleading profile': [
      'Stolen or AI-generated photos',
      'Catfishing — different person in person',
      'Impersonation of someone else',
      'Underage concern',
    ],
    'Harassment or abuse': [
      'Threats or intimidation',
      'Hate speech or slurs',
      'Unwanted sexual content',
      'Stalking or repeated unwanted contact',
      'Misgendering or attacks on identity',
    ],
    'Scams and fraud': [
      'Asking for money or gifts',
      'Crypto / investment pitch',
      'Fake job, housing, or ticket offer',
      'Phishing links or off-app pressure',
    ],
    'Inappropriate content': [
      'Nudity or sexual content I didn\'t consent to',
      'Violent or graphic media',
      'Spam or advertising',
    ],
    'Immediate safety concern': [
      'Self-harm signals',
      'Dangerous behaviour at a meetup',
      'Something else urgent',
    ],
  };

  /// The overflow sheet shown from any profile / chat / call / Moment.
  static void showForMember(
    BuildContext context, {
    required Member member,
    required String surface, // e.g. 'Profile', 'Chat', 'Spark call', 'Moment'
    VoidCallback? onBlocked,
  }) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Safety', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'About ${member.firstName} · from $surface',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report'),
            subtitle: const Text('Goes to a human Trust team. You stay anonymous to them.'),
            onTap: () {
              Navigator.of(context).pop();
              showReportFlow(context, member: member, surface: surface);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: AppColors.emberCrimson),
            title: const Text('Block'),
            subtitle: const Text('Instant. They disappear and cannot contact you.'),
            onTap: () {
              Navigator.of(context).pop();
              showBlockConfirmation(context,
                  member: member, onBlocked: onBlocked);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Appeal a decision'),
            subtitle: const Text('For warnings or actions on YOUR account.'),
            onTap: () {
              Navigator.of(context).pop();
              showAppealsEntry(context);
            },
          ),
        ],
      ),
    );
  }

  /// S-049: walk the structured tree — pick a category, then a specific
  /// reason, then submit. [member] is null for general reports filed from
  /// the Trust & Safety Centre. Confirmation follows S-051: case reference,
  /// response SLA, and a pointer to the appeals path.
  static void showReportFlow(
    BuildContext context, {
    Member? member,
    required String surface,
  }) {
    String? category;
    String? reason;
    final details = TextEditingController();
    bool submitting = false;
    showGlassSheet<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              member == null ? 'Make a report' : 'Report ${member.firstName}',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick what fits best — it routes your report to the right '
              'reviewers with the right evidence. Reports are reviewed by '
              'people, within 24 hours. In an emergency, contact local '
              'emergency services first.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (category == null) ...[
              for (final c in reportTree.keys)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => category = c),
                ),
            ] else ...[
              TextButton.icon(
                onPressed: () => setState(() {
                  category = null;
                  reason = null;
                }),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(category!),
              ),
              RadioGroup<String>(
                groupValue: reason,
                onChanged: (v) => setState(() => reason = v),
                child: Column(
                  children: [
                    for (final r in reportTree[category]!)
                      RadioListTile<String>(
                        value: r,
                        title: Text(r),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              // S-049 step 3: optional details + evidence. Evidence is
              // auto-attached from the sealed Safety Vault where a report
              // concerns chat/call content — the member never uploads
              // their own screenshots as "proof".
              TextField(
                controller: details,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Anything else? (optional)',
                  hintText: 'Details help the reviewer. Evidence from this '
                      'conversation is attached automatically (sealed).',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: reason == null || submitting
                    ? null
                    : () async {
                        _sound.safetyHaptic(); // NO sound on safety actions.
                        setState(() => submitting = true);
                        // POST the report (tree path + surface + sealed
                        // evidence refs) -> structured Trust queue (S-057).
                        // AI-05 pre-screens; HUMANS decide enforcement.
                        final ref = await Services.backend.submitReport(
                          category: category!,
                          reason: reason!,
                          details: details.text.trim().isEmpty
                              ? null
                              : details.text.trim(),
                          reportedUserId: member?.id,
                          surface: surface,
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        // S-051: a real confirmation SCREEN with the
                        // server-issued reference (mock: CN-DEMO).
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReportConfirmationScreen(
                              caseRef: ref,
                              category: category!,
                            ),
                          ),
                        );
                      },
                child: Text(submitting ? 'Sending…' : 'Submit report'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// S-051 / S-052: the appeals entry point.
  ///
  /// Linked from: this safety sheet, the Trust & Safety Centre, and every
  /// enforcement notice. Covers warnings (acknowledge OR appeal — the REA
  /// warnings/acknowledge pattern) and enforcement decisions (restriction,
  /// removal). A human reviews every appeal; the outcome arrives by
  /// notification. Appeals are free and never paywalled.
  static void showAppealsEntry(BuildContext context) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Appeal a decision', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'If we warned, restricted, or removed your account and you '
            'believe it was a mistake, you can appeal here. You can also '
            'acknowledge a warning if you understand it and accept it.\n\n'
            'Every appeal is reviewed by a person — not the system that '
            'flagged you. You\'ll get the outcome by notification, usually '
            'within 48 hours.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              _sound.safetyHaptic();
              // POST the appeal -> appeals queue (S-057), linked to the
              // original case. Statuses render in the Trust & Safety
              // Centre (S-052).
              final ref = await Services.backend.submitAppeal(
                subject: 'Account decision appeal',
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Appeal started · Ref $ref · Track it in Trust & Safety Centre → Your cases.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.gavel_outlined, size: 18),
            label: const Text('Start an appeal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  /// S-050B: instant block with consequence-clear copy.
  static void showBlockConfirmation(
    BuildContext context, {
    required Member member,
    VoidCallback? onBlocked,
  }) {
    showGlassSheet<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Block ${member.firstName}?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'They will be removed everywhere — matches, chats, Moments — '
            'and will not be told it was you. You can unblock later in Privacy Centre.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              _sound.safetyHaptic();
              // Server removes both directions immediately (blocks table
              // + trigger); the local callback lets the host surface
              // render its tombstone/empty state at once.
              await Services.backend.applyBlock(member.id);
              onBlocked?.call();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.firstName} blocked.')),
              );
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            child: const Text('Block now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
