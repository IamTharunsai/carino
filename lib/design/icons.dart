import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Figma icon set (assets/icons, exported from the file). Use
/// `CarinoIcon(CarinoIcons.heart)`; pass [color] to tint (e.g. active tab).
abstract final class CarinoIcons {
  static const heart = 'assets/icons/heart.svg';
  static const heartWhite = 'assets/icons/heart_white.svg';
  static const heartTab = 'assets/icons/heart_tab.svg';
  static const shield = 'assets/icons/shield.svg';
  static const shieldPrimary = 'assets/icons/shield_primary.svg';
  static const back = 'assets/icons/back.svg';
  static const eye = 'assets/icons/eye.svg';
  static const close = 'assets/icons/close.svg';
  static const spark = 'assets/icons/spark.svg';
  static const filter = 'assets/icons/filter.svg';
  static const search = 'assets/icons/search.svg';
  static const play = 'assets/icons/play.svg';
  static const chat = 'assets/icons/chat.svg';
  static const calendar = 'assets/icons/calendar.svg';
  static const user = 'assets/icons/user.svg';
}

class CarinoIcon extends StatelessWidget {
  const CarinoIcon(this.asset, {super.key, this.size = 22, this.color, this.semanticLabel});
  final String asset;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        semanticsLabel: semanticLabel,
        colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );
}
