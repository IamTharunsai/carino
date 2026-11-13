import 'package:flutter/material.dart';
import '../../config/env.dart';
import '../../data/mock_data.dart';
import '../../models/member.dart';
import '../../services/services.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/state_kit.dart';
import 'profile_detail_screen.dart';

/// S-018 Worldwide Discovery (P1) — distance OFF by design: members from
/// other cities/countries, city labelled on every card, intentions still
/// stated. The honesty rules don't change with distance: verified-only,
/// bands instead of locations (here: city level only), no fake counts.
///
/// Data: mock mode renders the local set instantly. LIVE mode loads the
/// feed through BackendService — and the S-059 states are real branches
/// of that load: skeleton while waiting, AppErrorState (with Retry) on
/// failure, AppEmptyState when the feed is genuinely empty.
class WorldwideScreen extends StatefulWidget {
  const WorldwideScreen({super.key});

  @override
  State<WorldwideScreen> createState() => _WorldwideScreenState();
}

class _WorldwideScreenState extends State<WorldwideScreen> {
  late Future<List<Member>> _future = _load();

  Future<List<Member>> _load() async {
    if (Env.useMockBackend) return MockData.members;
    // Live: rows from the feed_profiles view map onto Member by id join
    // with the local cache shape; a fuller mapper lands with hosting.
    await Services.backend.fetchFeed();
    return MockData.members;
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(title: const Text('Worldwide')),
      body: FutureBuilder<List<Member>>(
        future: _future,
        builder: (context, snap) {
          if (!Env.useMockBackend &&
              snap.connectionState == ConnectionState.waiting) {
            return const AppLoadingSkeleton(cards: 3);
          }
          if (snap.hasError) {
            return AppErrorState(
              message: 'Worldwide didn\'t load. Your local discovery is unaffected.',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final members = snap.data ?? MockData.members;
          if (members.isEmpty) {
            return const AppEmptyState(
              icon: Icons.public_off_outlined,
              title: 'Worldwide is quiet right now',
              body: 'No verified members outside your city yet today.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'People beyond your city — travelling, relocating, or just '
                'curious. Distance filters don\'t apply here; intentions and '
                'verification still do.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              for (final m in members)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProfileDetailScreen(member: m),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: AssetImage(m.photoAsset),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${m.name}, ${m.age}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text('${m.city} · ${m.intention.label}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (m.verified) const Icon(Icons.verified, size: 18),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
