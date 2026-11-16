import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/env.dart';
import '../../data/mock_data.dart';
import '../../models/creator.dart';
import '../../services/links.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/copy_text.dart';
import '../../widgets/gift_sheet.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/media.dart';
import '../../widgets/spark_button.dart';

/// Someone's public profile (from the Feed or a shared link): posts grid,
/// Follow, Subscribe (their paid posts + comments), Gift, Share.
class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key, required this.creatorId, required this.name});
  final String creatorId;
  final String name;

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final _prefs = Services.prefs;
  // Demo price; live: the creator sets it (creatorPriceOptionsCents).
  static const _priceCents = 499;

  bool get _following => _prefs.following.contains(widget.creatorId);
  bool get _subscribed => _prefs.subscriptions.contains(widget.creatorId);

  void _toggleFollow() => setState(() {
        _following ? _prefs.following.remove(widget.creatorId) : _prefs.following.add(widget.creatorId);
        _prefs.save();
      });

  void _subscribe() {
    if (_subscribed) {
      setState(() => _prefs.subscriptions.remove(widget.creatorId));
      _prefs.save();
      return;
    }
    final price = '\$${(_priceCents / 100).toStringAsFixed(2)}';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (s) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Subscribe to ${widget.name}', style: Theme.of(s).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('$price a month. Their subscriber-only posts, plus you can comment. '
                '${widget.name} keeps ${(creatorShare * 100).round()}%. Cancel any time.'),
            const SizedBox(height: 14),
            SparkButton(
              label: 'Subscribe · $price/mo',
              icon: Icons.star,
              onPressed: () {
                Navigator.pop(s);
                if (!Env.useMockBackend) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Subscriptions open when store products are live — nothing was charged.")));
                  return;
                }
                setState(() => _prefs.subscriptions.add(widget.creatorId));
                _prefs.save();
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('You’re subscribed to ${widget.name} ✨ (demo — no charge)')));
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final posts = MockData.feed.where((f) => f.creatorId == widget.creatorId).toList();
    final online = MockData.isOnline(widget.creatorId);
    return GlassScaffold(
      appBar: AppBar(title: Text(widget.name), actions: [
        IconButton(
          icon: const Icon(Icons.send_outlined),
          tooltip: 'Share profile',
          onPressed: () async {
            if (await copyText(context, shareLink(widget.creatorId)) && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile link copied 💌')));
            }
          },
        ),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              child: Row(children: [
                const Icon(Icons.phone_iphone, color: AppColors.sparkCoral),
                const SizedBox(width: 10),
                const Expanded(child: Text('Better in the app — get Cariño on your phone.')),
                TextButton(onPressed: () => launchUrl(Uri.parse(siteUrl)), child: const Text('Get the app')),
              ]),
            ),
          ),
        Row(children: [
          Stack(children: [
            CircleAvatar(radius: 40, backgroundImage: AssetImage(posts.isEmpty ? MockData.currentUser.photoAsset : posts.first.imageAsset)),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                  border: Border.all(color: AppColors.midnight, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.name, style: t.titleLarge),
              Text(online ? 'Active now' : 'Not active right now', style: t.bodySmall),
              Text('${posts.length} posts', style: t.bodySmall),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: SparkButton(label: _following ? 'Following' : 'Follow', secondary: _following, onPressed: _toggleFollow)),
          const SizedBox(width: 8),
          Expanded(
            child: SparkButton(
              label: _subscribed ? 'Subscribed' : 'Subscribe',
              icon: Icons.star_outline,
              secondary: !_subscribed,
              onPressed: _subscribe,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Send a gift',
            onPressed: () => showGiftSheet(context, widget.name),
          ),
        ]),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final p = posts[i];
            final locked = p.subscribersOnly && !_subscribed;
            return GestureDetector(
              onTap: locked ? _subscribe : null,
              child: Stack(fit: StackFit.expand, children: [
                MediaImage(p.imageAsset),
                if (locked)
                  Container(
                    color: AppColors.midnight.withValues(alpha: 0.75),
                    child: const Center(child: Icon(Icons.lock_outline, color: AppColors.warmIvory)),
                  ),
              ]),
            );
          },
        ),
      ]),
    );
  }
}
