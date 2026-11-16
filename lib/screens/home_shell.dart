import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../services/services.dart';
import '../widgets/glass_card.dart';
import 'chats/chat_list_screen.dart';
import 'connect/connect_screen.dart';
import 'discover/discover_screen.dart';
import 'stage/creator_profile_screen.dart';
import 'stage/stage_screen.dart';
import '../services/links.dart';
import 'you/my_profile_screen.dart';

/// The five-tab shell: Feed · Dates · Chats · Plans · You. Floating GLASS bottom bar over content; each tab keeps its
/// own navigation stack/state (IndexedStack). Badge counts are REAL
/// unread/invite counts only — never inflated engagement bait.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    pendingProfile.addListener(_openShared);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openShared());
  }

  @override
  void dispose() {
    pendingProfile.removeListener(_openShared);
    super.dispose();
  }

  /// A shared profile link opens that profile once you're in the app.
  void _openShared() {
    final id = pendingProfile.value;
    if (id == null || !mounted) return;
    pendingProfile.value = null;
    final name = MockData.feed.where((f) => f.creatorId == id).map((f) => f.creatorName).firstOrNull ?? 'Profile';
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => CreatorProfileScreen(creatorId: id, name: name)));
  }

  int get _unreadChats =>
      MockData.conversations().fold(0, (sum, c) => sum + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    final tabs = <_TabSpec>[
      // Faces first: the social Feed, then the verified 21+ Dates deck.
      const _TabSpec(Icons.play_circle_outline, Icons.play_circle, 'Feed'),
      const _TabSpec(Icons.local_fire_department_outlined,
          Icons.local_fire_department, 'Dates'),
      _TabSpec(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats',
          badge: _unreadChats),
      const _TabSpec(Icons.event_outlined, Icons.event, 'Plans'),
      const _TabSpec(Icons.person_outline, Icons.person, 'You'),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          // Only the visible tab animates; hidden tabs pause their tickers.
          for (final (i, tab) in const <Widget>[
            StageScreen(),
            DiscoverScreen(),
            ChatListScreen(),
            ConnectScreen(),
            YouScreen(),
          ].indexed)
            TickerMode(enabled: i == _index, child: tab),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: GlassContainer(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Equal-width slots: labels never push the bar off-screen.
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _TabButton(
                    spec: tabs[i],
                    selected: _index == i,
                    onTap: () {
                      Services.analytics.screen(tabs[i].label);
                      setState(() => _index = i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.icon, this.selectedIcon, this.label, {this.badge = 0});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badge;
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.emberCrimson
        : Theme.of(context).textTheme.bodySmall?.color;
    return Semantics(
      label: '${spec.label} tab${spec.badge > 0 ? ', ${spec.badge} unread' : ''}',
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(selected ? spec.selectedIcon : spec.icon,
                      color: color, size: 24),
                  if (spec.badge > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.emberCrimson,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          '${spec.badge}',
                          style: const TextStyle(
                              color: AppColors.warmIvory, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(fontSize: 11, color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
