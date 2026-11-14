import 'package:flutter/foundation.dart';

/// Privacy-first product analytics: screen views and key actions, counted
/// ON DEVICE in the demo and shown to the member in You → Your activity.
///
/// Rules (blueprint + privacy labels):
///  - Never log message text, photos, locations or who you looked at —
///    only event names and counts.
///  - INTEGRATION POINT: production forwards the same events to a
///    PostHog-class provider (D-13), with an opt-out in Privacy Centre.
class AnalyticsService extends ChangeNotifier {
  final Map<String, int> _screens = {};
  final Map<String, int> _actions = {};
  final List<(DateTime, String)> _recent = [];
  bool enabled = true;

  void setEnabled(bool v) {
    enabled = v;
    notifyListeners();
  }

  Map<String, int> get screens => Map.unmodifiable(_screens);
  Map<String, int> get actions => Map.unmodifiable(_actions);
  List<(DateTime, String)> get recent => List.unmodifiable(_recent);

  void screen(String name) => _bump(_screens, 'screen', name);
  void action(String name) => _bump(_actions, 'action', name);

  void _bump(Map<String, int> map, String kind, String name) {
    if (!enabled) return;
    map[name] = (map[name] ?? 0) + 1;
    _recent.insert(0, (DateTime.now(), '$kind:$name'));
    if (_recent.length > 50) _recent.removeLast();
    notifyListeners();
  }

  /// Most-used first.
  List<MapEntry<String, int>> top(Map<String, int> map, [int n = 8]) {
    final e = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return e.take(n).toList();
  }

  void clear() {
    _screens.clear();
    _actions.clear();
    _recent.clear();
    notifyListeners();
  }
}
