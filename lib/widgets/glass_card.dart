import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Frosted-glass surface (blueprint DESIGN SYSTEM).
/// Glass is for SURFACES (cards, sheets, nav) — primary actions stay solid.
/// BackdropFilter blur + translucent tint + 1pt hairline border + soft shadow.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radiusCard,
    this.opacity,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Defaults to the card tint (0.60); sheets pass AppColors.glassSheetOpacity.
  final double? opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fill = brightness == Brightness.dark
        ? AppColors.glassFillDark(opacity ?? AppColors.glassCardOpacity)
        : AppColors.glassFillLight((opacity ?? AppColors.glassCardOpacity) + 0.15);
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurSigma,
          sigmaY: AppColors.glassBlurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.glassBorder(brightness), width: 1),
          ),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.glassShadow,
      ),
      child: content,
    );
    if (onTap == null) return shadowed;
    return GestureDetector(onTap: onTap, child: shadowed);
  }
}

/// Scaffold with a full-bleed photographic background (approved imagery)
/// under a soft theme scrim — the "first-eye" look of the brand.
/// Text over photography keeps a scrim so contrast passes WCAG AA.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.backgroundAsset,
    this.appBar,
    this.bottomBar,
    this.scrimOpacity = 0.45,
  });

  final Widget body;
  final String? backgroundAsset;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final double scrimOpacity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: appBar,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (backgroundAsset != null)
            Image.asset(backgroundAsset!, fit: BoxFit.cover)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.midnight, AppColors.plumCharcoal]
                      : [AppColors.porcelain, const Color(0xFFF3E2E4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          // Scrim for legibility (never invert/desaturate the imagery).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? AppColors.midnight : AppColors.porcelain)
                      .withValues(alpha: scrimOpacity + 0.25),
                  (isDark ? AppColors.midnight : AppColors.porcelain)
                      .withValues(alpha: scrimOpacity),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(child: body),
        ],
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// Shows a modal glass sheet (radius 24 top corners, 80% tint per blueprint).
Future<T?> showGlassSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: GlassContainer(
        radius: AppTheme.radiusCard,
        opacity: AppColors.glassSheetOpacity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: child,
      ),
    ),
  );
}
