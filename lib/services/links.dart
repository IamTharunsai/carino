import 'package:flutter/foundation.dart';

/// Profile share links. One https link works everywhere: the app opens it
/// (Android App Links / iOS Universal Links), and without the app the
/// website shows the profile with a "Get the app" banner.
const siteUrl = 'https://carino-liard.vercel.app';

String shareLink(String profileId) => '$siteUrl/#/u/$profileId';

final _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// The profile id in `/u/<id>`, `#/u/<id>` or `carino://u/<id>`; else null.
String? profileIdFromLink(Uri u) => _idFor(u, 'u');

/// The circle id in a group invite link (`#/c/<id>`); else null.
String? circleIdFromLink(Uri u) => _idFor(u, 'c');

String? _idFor(Uri u, String kind) {
  final path = u.fragment.isNotEmpty
      ? u.fragment
      : u.scheme == 'carino'
          ? '/${u.host}${u.path}'
          : u.path;
  final parts = path.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length != 2 || parts[0] != kind || !_id.hasMatch(parts[1])) return null;
  return parts[1];
}

/// Set from the link that opened the app; Home opens it once signed in.
final pendingProfile = ValueNotifier<String?>(null);

/// Set from a group invite link; Home opens that circle.
final pendingCircle = ValueNotifier<String?>(null);
