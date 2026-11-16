import 'package:carino/services/links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('share link round-trips to the profile id', () {
    final link = shareLink('c-clay');
    expect(profileIdFromLink(Uri.parse(link)), 'c-clay');
  });

  test('accepts path, hash and app-scheme forms; rejects others', () {
    expect(profileIdFromLink(Uri.parse('https://carino-liard.vercel.app/u/f-sam')), 'f-sam');
    expect(profileIdFromLink(Uri.parse('carino://u/f-sam')), 'f-sam');
    expect(profileIdFromLink(Uri.parse('https://carino-liard.vercel.app/')), isNull);
    expect(profileIdFromLink(Uri.parse('https://carino-liard.vercel.app/#/u/../x')), isNull);
  });
}
