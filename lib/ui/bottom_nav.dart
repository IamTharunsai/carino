import 'package:flutter/material.dart';
import '../design/icons.dart';
import '../design/tokens.dart';
import '../design/type.dart';

class CarinoTab {
  const CarinoTab(this.icon, this.label, {this.badge = 0});
  final String icon;
  final String label;
  final int badge;
}

/// Figma "Bottom navigation": white bar, 1pt line, radius 24, 68 tall,
/// 12 from the screen sides. Each tab 58 tall, radius 18; the active tab
/// sits on blush with primary icon + label, the rest are secondary.
class CarinoBottomNav extends StatelessWidget {
  const CarinoBottomNav({super.key, required this.tabs, required this.index, required this.onTap});
  final List<CarinoTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CarinoColors.surface,
              border: Border.all(color: CarinoColors.line),
              borderRadius: BorderRadius.circular(CarinoRadius.card),
            ),
            child: Row(children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(child: _TabItem(tab: tabs[i], selected: i == index, onTap: () => onTap(i))),
            ]),
          ),
        ),
      );
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected, required this.onTap});
  final CarinoTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? CarinoColors.primary : CarinoColors.secondary;
    return Semantics(
      label: '${tab.label} tab${tab.badge > 0 ? ', ${tab.badge} unread' : ''}',
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Material(
          color: selected ? CarinoColors.blush : Colors.transparent,
          borderRadius: BorderRadius.circular(CarinoRadius.chip),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CarinoRadius.chip),
            child: SizedBox(
              height: 58,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Badge(
                  isLabelVisible: tab.badge > 0,
                  backgroundColor: CarinoColors.primary,
                  label: Text('${tab.badge}'),
                  child: CarinoIcon(tab.icon, color: color),
                ),
                const SizedBox(height: 6),
                Text(tab.label, style: CarinoText.tab.copyWith(color: color), maxLines: 1),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
