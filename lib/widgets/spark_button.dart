import 'package:flutter/material.dart';
import '../models/member.dart';
import '../theme/app_colors.dart';

/// Primary action button — SOLID Ember Crimson, min height 50, radius 16.
/// (DESIGN SYSTEM rule: primary = solid. Glass is for surfaces, not action.)
class SparkButton extends StatelessWidget {
  const SparkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.iconAtEnd = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Secondary = glass style with hairline border.
  final bool secondary;

  /// Put the icon after the label (e.g. a forward arrow).
  final bool iconAtEnd;

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        iconAlignment: iconAtEnd ? IconAlignment.end : IconAlignment.start,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: AppColors.glassBorder(Theme.of(context).brightness)),
          foregroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.warmIvory : AppColors.midnight,
          shape: const StadiumBorder(),
        ),
      );
    }
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.loveGradient : null,
        color: enabled ? null : AppColors.line,
        borderRadius: BorderRadius.circular(999),
        boxShadow: enabled
            ? const [BoxShadow(color: Color(0x336B2D5C), blurRadius: 14, offset: Offset(0, 6))]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        iconAlignment: iconAtEnd ? IconAlignment.end : IconAlignment.start,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

/// Intention chip — colour is never the only signal: it always carries text.
/// Selected = solid crimson; unselected = thin glass (DESIGN SYSTEM).
class IntentionChip extends StatelessWidget {
  const IntentionChip({
    super.key,
    required this.intention,
    required this.selected,
    required this.onTap,
  });

  final Intention intention;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ChoiceChip(
      label: Text(intention.label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: brightness == Brightness.dark
          ? AppColors.glassFillDark(0.6)
          : AppColors.glassFillLight(0.75),
      selectedColor: AppColors.blush,
      labelStyle: TextStyle(
        color: selected
            ? AppColors.emberCrimson
            : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? Colors.transparent : AppColors.glassBorder(brightness),
      ),
      shape: const StadiumBorder(),
      showCheckmark: false,
    );
  }
}

/// Small verified badge — ID + liveness + photo match passed (S-007).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified · ID and selfie checked',
      child: Icon(Icons.verified, size: size, color: AppColors.verifiedGold),
    );
  }
}

/// Round glass icon button used on cards and in-call controls.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.filled = false,
    this.onLongPress,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final bool filled; // solid crimson variant (e.g. Like)

  /// Optional secondary action (e.g. long-press Like for note/gift/Spark).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: filled
            ? AppColors.emberCrimson
            : Theme.of(context).brightness == Brightness.dark
                ? AppColors.plumCharcoal
                : AppColors.blush,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon,
                color: filled ? AppColors.warmIvory : Theme.of(context).colorScheme.onSurface, size: 22),
          ),
        ),
      ),
    );
  }
}
