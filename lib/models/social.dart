/// Social platform, Phase 1: circles, friends, group chats with a Plan
/// button. Pure Dart (no Flutter) so the rules are unit-tested.

/// Who a post, story or chat is for. Private is the default — a member
/// picks a circle every time they share.
enum Circle {
  inner('Inner circle', 'Family and best friends'),
  friends('Friends', 'Inner circle + friends'),
  dates('Dates', 'Your 21+ verified matches only'),
  everyone('All connections', 'Friends and matches');

  const Circle(this.label, this.hint);
  final String label;
  final String hint;
}

/// Can someone you've placed in [viewer] see a post shared to [audience]?
/// Friends posts include the inner circle; Dates is its own world (your
/// friends never see what you share with matches, and vice versa).
bool circleCanSee(Circle audience, Circle viewer) => switch (audience) {
      Circle.inner => viewer == Circle.inner,
      Circle.friends => viewer == Circle.inner || viewer == Circle.friends,
      Circle.dates => viewer == Circle.dates,
      Circle.everyone => true,
    };

/// Your graph: which circle each person sits in. In-memory for the demo;
/// production stores it server-side (own rows only) — nobody can see which
/// circle you put them in.
class SocialGraph {
  SocialGraph(Map<String, Circle> initial) : _circles = {...initial};

  final Map<String, Circle> _circles;

  Circle? circleOf(String personId) => _circles[personId];
  void place(String personId, Circle circle) => _circles[personId] = circle;
  void remove(String personId) => _circles.remove(personId);
  List<String> inCircle(Circle c) =>
      [for (final e in _circles.entries) if (e.value == c) e.key];
  bool isFriend(String id) =>
      _circles[id] == Circle.inner || _circles[id] == Circle.friends;
}

/// A group chat between friends.
class GroupChat {
  GroupChat({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.messages,
    this.unreadCount = 0,
  });

  final String id;
  String name;
  final List<String> memberIds;
  final List<GroupMessage> messages;
  int unreadCount;
  PlanPoll? poll;
}

class GroupMessage {
  GroupMessage({
    required this.senderId, // 'me' for the signed-in member
    required this.text,
    required this.timeLabel,
    this.isSystem = false,
  });

  final String senderId;
  final String text;
  final String timeLabel;

  /// Poll results, plan set, member joined… rendered centred.
  final bool isSystem;
}

/// "We should hang out" -> a real plan. Everyone votes on options; the
/// plan locks when one option has a majority of the group.
class PlanPoll {
  PlanPoll({required this.placeType, required List<String> options})
      : votes = {for (final o in options) o: <String>{}};

  final String placeType;

  /// option -> voter ids (one vote per person, changeable).
  final Map<String, Set<String>> votes;

  void vote(String voterId, String option) {
    for (final v in votes.values) {
      v.remove(voterId);
    }
    votes[option]?.add(voterId);
  }

  String? myVote(String voterId) {
    for (final e in votes.entries) {
      if (e.value.contains(voterId)) return e.key;
    }
    return null;
  }

  int get totalVotes => votes.values.fold(0, (s, v) => s + v.length);

  /// The option with a strict majority of [groupSize], else null.
  String? winner(int groupSize) {
    for (final e in votes.entries) {
      if (e.value.length * 2 > groupSize) return e.key;
    }
    return null;
  }
}

/// Suggest plan times from what the group already said. A transparent
/// keyword heuristic ("Suggested from your chat") — the live AI proxy can
/// replace it, but the UI never claims more than it knows.
List<String> suggestPlanTimes(Iterable<String> texts) {
  const days = {
    'tonight': 'Tonight · 20:00',
    'tomorrow': 'Tomorrow · 19:00',
    'friday': 'Fri · 19:30',
    'saturday': 'Sat · 14:00',
    'sunday': 'Sun · 12:00',
    'weekend': 'Sat · 19:00',
  };
  final found = <String>[];
  for (final t in texts) {
    final lower = t.toLowerCase();
    for (final e in days.entries) {
      if (lower.contains(e.key) && !found.contains(e.value)) found.add(e.value);
    }
  }
  for (final fallback in ['Fri · 19:30', 'Sat · 14:00', 'Sun · 12:00']) {
    if (found.length >= 3) break;
    if (!found.contains(fallback)) found.add(fallback);
  }
  return found.take(3).toList();
}
