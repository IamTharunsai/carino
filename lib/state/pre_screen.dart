import '../models/agent.dart';
import '../models/member.dart';
import 'drop_tuning.dart';

/// Wave 4 · Agent Pre-Screen (MASTER-BUILD-PLAN A2). Pure logic, no
/// Flutter imports — the vetting card is computed ONLY from the two
/// real profiles and the store's block list, so every line on the
/// card can be re-derived and audited. The agent filters and
/// explains; it never scores compatibility with invented numbers and
/// it never sends anything — the human taps "Start chatting".

/// Builds the pre-screen summary for [other] as seen by [me].
PreScreenSummary buildPreScreen({
  required Member me,
  required Member other,
  required Set<String> blockedIds,
}) {
  // --- Intentions: stated plainly, aligned or not ---
  final aligned = me.intention == other.intention;
  final intentionLine = aligned
      ? 'Both here for ${me.intention.label} — ${me.intention.tagline.toLowerCase()}'
      : 'You\'re here for ${me.intention.label}; ${other.firstName} is '
          'here for ${other.intention.label}. The card says it plainly — '
          'you decide if that fits.';

  // --- Shared signals: real fields only, best first ---
  final signals = <String>[];
  final myInterests = me.interests.toSet();
  final sharedExact =
      other.interests.where(myInterests.contains).toList();
  for (final interest in sharedExact.take(2)) {
    signals.add('You both like $interest');
  }
  // My interests that surface in their profile TEXT (a prompt answer,
  // the headline) — labelled as a mention, never upgraded to a shared
  // interest it isn't.
  for (final interest in me.interests) {
    if (signals.length >= 4) break;
    if (sharedExact.contains(interest)) continue;
    if (tuneTermMatches(other, interest.toLowerCase())) {
      signals.add('Your interest "$interest" shows up in their profile');
    }
  }
  if (me.city == other.city) {
    signals.add('Both in ${me.city}');
  }
  if (me.pace == other.pace) {
    signals.add('Same pace: ${me.pace}');
  }
  if (other.hasRealCaptureMedia) {
    signals.add('Their media is Real Capture — shot in-app, unedited');
  }
  if (other.onlineNow) {
    signals.add('Online now');
  }

  // --- Safety: the block list is the only hard state the store
  // holds between two members (reports live in the case system and
  // are never rendered as a score). ---
  final blocked = blockedIds.contains(other.id);
  return PreScreenSummary(
    memberId: other.id,
    verified: other.verified,
    intentionAligned: aligned,
    intentionLine: intentionLine,
    sharedSignals: signals,
    safety: blocked ? PreScreenSafety.blocked : PreScreenSafety.clear,
    safetyLine: blocked
        ? 'You blocked ${other.firstName}. A blocked member can\'t be '
            'matched with you — this chat stays closed.'
        : 'No blocks between you. Block and report stay one tap away '
            'in every chat, and safety is never paywalled.',
  );
}
