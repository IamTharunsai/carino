import 'dart:async';

import 'package:carino/widgets/motion.dart';

/// Runs before every test file: looping background motion would keep
/// pumpAndSettle waiting forever, so tests see the still frame.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  stillBackgrounds = true;
  await testMain();
}
