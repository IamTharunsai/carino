import 'dart:io';
import 'package:flutter/services.dart';

/// Loads Roboto, Material Icons and the bundled brand fonts so widget tests
/// lay out like a real phone instead of the test engine's wide box font.
Future<void> loadRealFonts() async {
  final cache = '${_flutterRoot()}/bin/cache/artifacts/material_fonts';
  Future<void> family(String name, String dir, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File('$dir/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  const roboto = ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-italic.ttf'];
  await family('Roboto', cache, roboto);
  await family('CupertinoSystemText', cache, roboto);
  // Text with no explicit family falls back to the test box font; devices
  // use Roboto/SF. Register Roboto under that name for realism.
  await family('FlutterTest', cache, roboto);
  await family('CupertinoSystemDisplay', cache, roboto);
  await family('MaterialIcons', cache, ['materialicons-regular.otf']);
  await family('Poppins', 'assets/fonts', ['Poppins-Regular.ttf', 'Poppins-Medium.ttf',
      'Poppins-SemiBold.ttf', 'Poppins-Bold.ttf', 'Poppins-Italic.ttf']);
  await family('DM Serif Display', 'assets/fonts',
      ['DMSerifDisplay-Regular.ttf', 'DMSerifDisplay-Italic.ttf']);
}

/// FLUTTER_ROOT when set; otherwise walk up from the test runner binary
/// (<root>/bin/cache/artifacts/engine/<platform>/flutter_tester), so it works
/// on Windows dev machines and Linux CI alike.
String _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    if (Directory('${dir.path}/bin/cache/artifacts/material_fonts').existsSync()) return dir.path;
    dir = dir.parent;
  }
  throw StateError('Flutter SDK not found; set FLUTTER_ROOT');
}
