// Sync prefs survive a restart (save -> fresh load).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:carino/models/sync.dart';
import 'package:carino/services/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('style, comfort, notes and reflections round-trip; junk is ignored', () async {
    SharedPreferences.setMockInitialValues({});
    final a = UserPrefs();
    await a.load();
    a.myStyle = const TextingStyle(pace: ReplyPace.slow, humour: Humour.dry, loves: ['Jazz']);
    a.myComfort = const ComfortRules(photosAfterDays: 7, opensFirst: true);
    a.matchNotes['m-aria'] = 'Dog called Biscuit';
    a.reflections.add(const Reflection(category: 'Calm', good: true, liked: {ReflectTag.quiet}));
    await a.save();

    final b = UserPrefs();
    await b.load();
    expect(b.myStyle.pace, ReplyPace.slow);
    expect(b.myStyle.humour, Humour.dry);
    expect(b.myStyle.loves, ['Jazz']);
    expect(b.myComfort.photosAfterDays, 7);
    expect(b.myComfort.opensFirst, isTrue);
    expect(b.matchNotes['m-aria'], 'Dog called Biscuit');
    expect(b.reflections.single.liked, {ReflectTag.quiet});

    SharedPreferences.setMockInitialValues({'sync': '{not json'});
    final c = UserPrefs();
    await c.load(); // must not crash on a corrupt blob
    expect(c.myStyle.isEmpty, isTrue);
  });
}
