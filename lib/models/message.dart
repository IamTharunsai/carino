/// Chat modes (blueprint S-035 / S-036 / S-036B).
/// Switching modes always requires BOTH people to agree, and is prospective
/// only — Keep history is never retroactively vanished.
enum ChatMode { keep, vanish }

class Conversation {
  Conversation({
    required this.id,
    required this.memberId,
    required this.mode,
    required this.messages,
    this.unreadCount = 0,
    this.vanishMinutes = 60,
    this.planPinned = false,
    this.quietDays = 0,
  });

  final String id;
  final String memberId;
  ChatMode mode;
  final List<ChatMessage> messages;
  int unreadCount;

  /// Vanish expiry window (minutes) once Vanish mode is agreed.
  int vanishMinutes;

  /// A confirmed plan is pinned at the top of the conversation (S-040).
  bool planPinned;

  /// Days since either person last wrote. Drives the optional, kind
  /// Close the Loop nudge (never a public 'ghoster' label).
  int quietDays;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.timeLabel,
    this.isGameCard = false,
    this.gameTitle,
    this.dissolved = false,
    this.mediaAsset,
    this.viewOnce = false,
    this.mediaConsumed = false,
    this.isSystemNotice = false,
    this.expiresInLabel,
    this.unsent = false,
    this.reaction,
  });

  final String id;
  final String text;
  final bool fromMe;
  final String timeLabel;

  /// Game invites / results render as cards inside the conversation (S-031).
  final bool isGameCard;
  final String? gameTitle;

  /// Photo/video message (S-035 media send, S-037 viewer). Asset path in
  /// the scaffold; a signed storage URL in production.
  final String? mediaAsset;

  /// View-once media (S-035/S-037): removed after viewing; the consumed
  /// state renders a placeholder, never a broken image.
  final bool viewOnce;
  bool mediaConsumed;

  /// System notices render centred (e.g. the S-036 screenshot-DETECTED
  /// notice — detection only, never a prevention claim).
  final bool isSystemNotice;

  /// Vanish per-message expiry label (S-036), server-authoritative in
  /// production — the client displays the server's stated clock.
  final String? expiresInLabel;

  /// Unsend (S-035): tombstone behaviour — the bubble shows "Message
  /// unsent" within the stated limits.
  bool unsent;

  /// Single reaction shown on the bubble (S-035 long-press reactions).
  String? reaction;

  /// Vanish mode: set when the message's timer has ended (S-036 animation —
  /// gentle fade + height collapse, 300ms). In production the Safety Vault
  /// retains a sealed, report-only copy so abuse can still be evidenced —
  /// the UI never reveals this beyond the honest privacy copy.
  bool dissolved;
}

/// In-chat games (blueprint S-030/S-031). Every question is skippable;
/// both-answer reveal is the mechanic — answers bloom side by side.
class GameQuestion {
  const GameQuestion({required this.prompt, required this.options});
  final String prompt;
  final List<String> options;
}

class TwoTruthsRound {
  const TwoTruthsRound({required this.statements, required this.lieIndex});
  final List<String> statements;
  final int lieIndex;
}
