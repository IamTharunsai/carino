import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/services.dart';
import '../design/icons.dart';
import '../ui/bottom_nav.dart';
import 'chats/chat_list_screen.dart';
import 'connect/connect_screen.dart';
import 'discover/discover_screen.dart';
import 'stage/creator_profile_screen.dart';
import 'connect/circle_detail_screen.dart';
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
    pendingCircle.addListener(_openCircle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openShared();
      _openCircle();
    });
  }

  @override
  void dispose() {
    pendingProfile.removeListener(_openShared);
    pendingCircle.removeListener(_openCircle);
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

  void _openCircle() {
    final id = pendingCircle.value;
    if (id == null || !mounted) return;
    pendingCircle.value = null;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CircleDetailScreen(circleId: id)));
  }

  int get _unreadChats =>
      MockData.conversations().fold(0, (sum, c) => sum + c.unreadCount);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const CarinoTab(CarinoIcons.play, 'Feed'),
      const CarinoTab(CarinoIcons.heart, 'Dates'),
      CarinoTab(CarinoIcons.chat, 'Chats', badge: _unreadChats),
      const CarinoTab(CarinoIcons.calendar, 'Plans'),
      const CarinoTab(CarinoIcons.user, 'You'),
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
      bottomNavigationBar: CarinoBottomNav(
        tabs: tabs,
        index: _index,
        onTap: (i) {
          Services.analytics.screen(tabs[i].label);
          setState(() => _index = i);
        },
      ),
    );
  }
}
