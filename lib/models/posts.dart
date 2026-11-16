/// Your own posts on your profile grid. You choose how long each stays:
/// forever (like a normal profile post), 24 hours, or 7 days.
library;

enum Keep {
  forever('Keep forever', null),
  day('24 hours', Duration(hours: 24)),
  week('7 days', Duration(days: 7));

  const Keep(this.label, this.duration);
  final String label;
  final Duration? duration;
}

class MyPost {
  MyPost({required this.media, required this.caption, required this.created, required this.keep});
  final String media; // path; videos prefixed `video:`
  final String caption;
  final DateTime created;
  final Keep keep;

  DateTime? get expires => keep.duration == null ? null : created.add(keep.duration!);

  String? expiryLabel(DateTime now) {
    final e = expires;
    if (e == null) return null;
    final left = e.difference(now);
    return left.inHours >= 24 ? 'Disappears in ${left.inDays}d' : 'Disappears in ${left.inHours}h';
  }

  Map<String, Object?> toJson() =>
      {'m': media, 'c': caption, 't': created.toIso8601String(), 'k': keep.name};

  static MyPost fromJson(Map<String, Object?> j) => MyPost(
        media: '${j['m']}',
        caption: '${j['c'] ?? ''}',
        created: DateTime.parse('${j['t']}'),
        keep: Keep.values.asNameMap()[j['k']] ?? Keep.forever,
      );
}

/// Newest first, expired ones gone.
List<MyPost> visiblePosts(List<MyPost> all, DateTime now) =>
    all.where((p) => p.expires == null || p.expires!.isAfter(now)).toList()
      ..sort((a, b) => b.created.compareTo(a.created));
