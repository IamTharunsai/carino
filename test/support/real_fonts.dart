import 'dart:io';
import 'package:flutter/services.dart';

/// Loads real fonts so widget tests lay out like a phone instead of the test
/// engine's wide box font. Uses Flutter's cached Roboto + Material Icons when
/// present; CI runners often lack that cache, so the bundled Poppins (the
/// app's own UI font) stands in for every text family.
Future<void> loadRealFonts() async {
  Future<void> family(String name, String dir, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File('$dir/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  const poppins = ['Poppins-Regular.ttf', 'Poppins-Medium.ttf', 'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf', 'Poppins-Italic.ttf'];
  await family('Poppins', 'assets/fonts', poppins);
  await family('DM Serif Display', 'assets/fonts',
      ['DMSerifDisplay-Regular.ttf', 'DMSerifDisplay-Italic.ttf']);

  final cache = _materialFonts();
  final (dir, files) = cache == null
      ? ('assets/fonts', poppins)
      : (cache, const ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-italic.ttf']);
  // Text with no explicit family falls back to the test box font; devices
  // use Roboto/SF. Register a real font under those names.
  for (final name in ['Roboto', 'CupertinoSystemText', 'FlutterTest', 'CupertinoSystemDisplay']) {
    await family(name, dir, files);
  }
  if (cache != null) await family('MaterialIcons', cache, ['materialicons-regular.otf']);
}

/// `<flutter>/bin/cache/artifacts/material_fonts`, found via FLUTTER_ROOT or
/// by walking up from the test runner binary; null when not downloaded.
String? _materialFonts() {
  const rel = '/bin/cache/artifacts/material_fonts';
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && Directory('$env$rel').existsSync()) return '$env$rel';
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    if (Directory('${dir.path}$rel').existsSync()) return '${dir.path}$rel';
    dir = dir.parent;
  }
  return null;
}
