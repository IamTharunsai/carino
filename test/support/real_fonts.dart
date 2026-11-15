import 'dart:io';
import 'package:flutter/services.dart';

/// Loads Roboto, Material Icons and the bundled brand fonts so widget tests
/// lay out like a real phone instead of the test engine's wide box font.
Future<void> loadRealFonts() async {
  final cache = '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter'}'
      '/bin/cache/artifacts/material_fonts';
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
