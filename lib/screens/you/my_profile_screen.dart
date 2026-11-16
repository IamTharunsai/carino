import 'package:flutter/material.dart';
import '../onboarding/verification_flow_screen.dart';
import 'package:flutter/services.dart';
import '../../data/mock_data.dart';
import '../../models/posts.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/copy_text.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/media.dart';
import '../../widgets/spark_button.dart';
import '../onboarding/profile_creation_screen.dart';
import 'you_screen.dart';

/// You — your profile, the way people see it (Instagram-style): photo,
/// posts / followers / following, bio, Edit + Share, and your post grid.
/// ☰ opens Settings & account.
class YouScreen extends StatefulWidget {
  const YouScreen({super.key});

  @override
  State<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends State<YouScreen> {
  final _prefs = Services.prefs;

  // Demo: people who follow you come from the sample data; live, the server.
  int get _followers => MockData.likesYou.length + _prefs.liked.length ~/ 2;

  Future<void> _newPost() async {
    final media = await chooseMedia(context);
    if (media == null || !mounted) return;
    final caption = TextEditingController();
    var keep = Keep.forever;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (s) => StatefulBuilder(
        builder: (s, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(s).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(height: 200, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: MediaTile(media))),
            const SizedBox(height: 12),
            TextField(controller: caption, maxLength: 300, decoration: const InputDecoration(hintText: 'Say something cute…')),
            Text('How long should it stay?', style: Theme.of(s).textTheme.titleSmall),
            const SizedBox(height: 6),
            SegmentedButton<Keep>(
              showSelectedIcon: false,
              segments: [for (final k in Keep.values) ButtonSegment(value: k, label: Text(k.label))],
              selected: {keep},
              onSelectionChanged: (v) => set(() => keep = v.first),
            ),
            const SizedBox(height: 14),
            SparkButton(label: 'Share', icon: Icons.send, onPressed: () => Navigator.pop(s, true)),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _prefs.posts.add(
        MyPost(media: media, caption: caption.text.trim(), created: DateTime.now(), keep: keep)));
    _prefs.save();
  }

  void _openPost(MyPost p) {
    final label = p.expiryLabel(DateTime.now());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (s) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: MediaQuery.of(s).size.height * 0.55,
            child: isVideo(p.media) ? VideoClip(p.media) : MediaImage(p.media, fit: BoxFit.contain),
          ),
          if (p.caption.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(p.caption)),
          if (label != null) Text(label, style: Theme.of(s).textTheme.bodySmall),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete post'),
            onTap: () {
              setState(() => _prefs.posts.remove(p));
              _prefs.save();
              Navigator.pop(s);
            },
          ),
        ]),
      ),
    );
  }

  Widget _count(String n, String label) => Expanded(
        child: Column(children: [
          Text(n, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final me = _prefs.me;
    final t = Theme.of(context).textTheme;
    final posts = visiblePosts(_prefs.posts, DateTime.now());
    final photo = _prefs.photos.where((p) => !isVideo(p)).firstOrNull;
    return GlassScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Row(children: [
            Expanded(
              child: Row(children: [
                Flexible(child: Text(me.name, style: t.titleLarge, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                if (_prefs.mockVerified)
                  const Icon(Icons.verified, size: 18, color: AppColors.verifiedGold),
              ]),
            ),
            IconButton(icon: const Icon(Icons.add_box_outlined), tooltip: 'New post', onPressed: _newPost),
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Settings & account',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => const AccountCentreScreen()))
                  .then((_) => setState(() {})),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.emberCrimson.withValues(alpha: 0.2),
              child: ClipOval(
                child: SizedBox.square(
                  dimension: 84,
                  child: photo != null ? MediaImage(photo) : Image.asset(me.photoAsset, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _count('${posts.length}', 'Posts'),
            _count('$_followers', 'Followers'),
            _count('${_prefs.following.length}', 'Following'),
          ]),
          const SizedBox(height: 10),
          Text(me.headline, style: t.bodyMedium),
          if (me.interests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(me.interests.take(5).join(' · '), style: t.bodySmall),
            ),
          if (!_prefs.mockVerified) ...[
            const SizedBox(height: 10),
            GlassContainer(
              onTap: () => startVerification(context).then((_) => setState(() {})),
              child: Row(children: [
                const Icon(Icons.verified_outlined, color: AppColors.verifiedGold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Get your gold tick — 2 minutes, and people know you’re really you.',
                      style: t.bodyMedium),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: SparkButton(
                label: 'Edit profile',
                secondary: true,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(
                        builder: (_) => ProfileCreationScreen(onPublished: () => Navigator.of(context).pop())))
                    .then((_) => setState(() {})),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SparkButton(
                label: 'Share profile',
                secondary: true,
                onPressed: () async {
                  final ok = await copyText(context, 'https://carino-liard.vercel.app/@${me.name.toLowerCase()}');
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile link copied 💌')));
                    HapticFeedback.lightImpact();
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (posts.isEmpty)
            GlassContainer(
              onTap: _newPost,
              child: Column(children: [
                const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.sparkCoral),
                const SizedBox(height: 8),
                Text('Share your first moment', style: t.titleMedium),
                Text('Photos or videos. Keep them forever, or let them vanish after 24h or 7 days.',
                    style: t.bodySmall, textAlign: TextAlign.center),
              ]),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
              itemCount: posts.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _openPost(posts[i]),
                child: Stack(fit: StackFit.expand, children: [
                  MediaTile(posts[i].media),
                  if (posts[i].keep != Keep.forever)
                    const Positioned(right: 4, top: 4, child: Icon(Icons.timer_outlined, size: 16, color: AppColors.warmIvory)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
