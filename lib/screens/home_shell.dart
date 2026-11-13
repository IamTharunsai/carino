import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import 'chats/chat_list_screen.dart';
import 'connect/connect_screen.dart';
import 'discover/discover_screen.dart';
import 'moments/moments_screen.dart';
import 'you/you_screen.dart';

/// The five-tab shell (blueprint NAV & IA): Discover · Moments · Connect ·
/// Chats · You. Floating GLASS bottom bar over content; each tab keeps its
/// own navigation stack/state (IndexedStack). Badge counts are REAL
/// unread/invite counts only — never inflated engagement bait.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  int get _unreadChats =>
      MockData.conversations().fold(0, (sum, c) => sum + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    final tabs = <_TabSpec>[
      const _TabSpec(Icons.explore_outlined, Icons.explore, 'Discover'),
      const _TabSpec(Icons.auto_stories_outlined, Icons.auto_stories, 'Moments'),
      const _TabSpec(Icons.favorite_border, Icons.favorite, 'Connect'),
      _TabSpec(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats',
          badge: _unreadChats),
      const _TabSpec(Icons.person_outline, Icons.person, 'You'),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          DiscoverScreen(),
          MomentsScreen(),
          ConnectScreen(),
          ChatListScreen(),
          YouScreen(),
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
              for (var i = 0; i < tabs.length; i++)
                _TabButton(
                  spec: tabs[i],
                  selected: _index == i,
                  onTap: () => setState(() => _index = i),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  style: TextStyle(fontSize: 11, color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
