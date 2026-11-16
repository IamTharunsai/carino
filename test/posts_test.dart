import 'package:carino/models/posts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 15, 12);

  test('posts kept forever never disappear; timed ones do', () {
    final posts = [
      MyPost(media: 'a.jpg', caption: '', created: t0, keep: Keep.forever),
      MyPost(media: 'b.jpg', caption: '', created: t0, keep: Keep.day),
      MyPost(media: 'c.jpg', caption: '', created: t0, keep: Keep.week),
    ];
    expect(visiblePosts(posts, t0.add(const Duration(hours: 23))).length, 3);
    expect(visiblePosts(posts, t0.add(const Duration(days: 2))).map((p) => p.media), ['a.jpg', 'c.jpg']);
    expect(visiblePosts(posts, t0.add(const Duration(days: 30))).map((p) => p.media), ['a.jpg']);
  });

  test('posts round-trip through json', () {
    final p = MyPost(media: 'video:x', caption: 'hi', created: t0, keep: Keep.day);
    final back = MyPost.fromJson(p.toJson());
    expect(back.media, 'video:x');
    expect(back.keep, Keep.day);
    expect(back.created, t0);
  });

  test('expiry label is honest', () {
    final p = MyPost(media: 'a', caption: '', created: t0, keep: Keep.day);
    expect(p.expiryLabel(t0.add(const Duration(hours: 20))), 'Disappears in 4h');
    expect(MyPost(media: 'a', caption: '', created: t0, keep: Keep.forever).expiryLabel(t0), isNull);
  });
}
