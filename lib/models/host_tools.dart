/// Host tools the crowd's host asked for: bring an existing group in with
/// one link, and set your own check-in code for a plan.
library;

import '../services/links.dart' show siteUrl;

String groupInviteLink(String circleId) => '$siteUrl/#/c/$circleId';

/// Upper-case letters and digits only, 4–8 long; null if it can't be used.
String? cleanCheckInCode(String raw) {
  final c = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return c.length >= 4 && c.length <= 8 ? c : null;
}

/// A stable 5-character code when the host doesn't pick one.
String defaultCheckInCode(String planId) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  var h = 0;
  for (final u in planId.codeUnits) {
    h = (h * 31 + u) & 0x7fffffff;
  }
  return List.generate(5, (i) => alphabet[(h >> (i * 5)) % alphabet.length]).join();
}
