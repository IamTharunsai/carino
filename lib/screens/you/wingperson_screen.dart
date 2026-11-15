import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../services/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';
import '../../widgets/copy_text.dart';
import '../discover/profile_detail_screen.dart';

/// Wingperson — invite one friend by link to look over your Daily Drop and
/// suggest people. Only YOU can like. They never see your chats, matches or
/// anything outside the Drop cards, and you can revoke access at any time.
class WingpersonScreen extends StatefulWidget {
  const WingpersonScreen({super.key});

  @override
  State<WingpersonScreen> createState() => _WingpersonScreenState();
}

class _WingpersonScreenState extends State<WingpersonScreen> {
  bool get _active => Services.prefs.wingpersonActive;

  Future<void> _start() async {
    const link = 'https://carino.app/wing/demo-K4P9';
    if (!await copyText(context, link)) return;
    if (!mounted) return;
    setState(() => Services.prefs.wingpersonActive = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied — send it to one friend.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Sample suggestions from the friend (demo). Production: wing_picks rows.
    final picks = MockData.dailyDrop.take(2).toList();
    return GlassScaffold(
      appBar: AppBar(title: const Text('Wingperson')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Let a friend you trust look over your Daily Drop and point out '
            'who seems like your type. You still decide — only you can like.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 14),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What your friend can see', style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '✓ Your Daily Drop cards\n'
                  '✗ Your chats, matches, likes or settings\n'
                  '✗ Anything after you revoke the link',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!_active)
            SparkButton(
              label: 'Copy invite link',
              icon: Icons.link,
              onPressed: _start,
            )
          else ...[
            Text('Your friend suggested', style: text.titleMedium),
            const SizedBox(height: 8),
            for (final m in picks) ...[
              GlassContainer(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileDetailScreen(member: m),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundImage: AssetImage(m.photoAsset)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.firstName}, ${m.age}',
                              style: text.titleMedium),
                          Text('“You two would never stop talking.”',
                              style: text.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            SparkButton(
              label: 'Revoke access',
              icon: Icons.link_off,
              secondary: true,
              onPressed: () {
                setState(() => Services.prefs.wingpersonActive = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Revoked. The link stopped working.')),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Suggestions are sample data in this demo.',
            style: text.bodySmall?.copyWith(color: AppColors.softRose),
          ),
        ],
      ),
    );
  }
}
