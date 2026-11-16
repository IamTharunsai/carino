/// Your Flame 🔥 with someone: days in a row you've kept in touch (a
/// message, a game or a one-tap Heartbeat). One missed day is forgiven —
/// love shouldn't feel like homework.
library;

class Flame {
  const Flame(this.days, this.lastDay);
  final int days;
  final DateTime lastDay; // date only

  Map<String, Object> toJson() => {'d': days, 't': lastDay.toIso8601String()};
  static Flame fromJson(Map<String, Object?> j) =>
      Flame((j['d'] as num).toInt(), DateTime.parse('${j['t']}'));
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

Flame feedFlame(Flame? f, DateTime now) {
  final today = _day(now);
  if (f == null) return Flame(1, today);
  final gap = today.difference(f.lastDay).inDays;
  if (gap <= 0) return f;
  if (gap <= 2) return Flame(f.days + 1, today);
  return Flame(1, today);
}

const heartbeatEmojis = ['💓', '😘', '🔥', '🌹', '🥰', '😏', '☕'];
