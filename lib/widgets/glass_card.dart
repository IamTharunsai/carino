import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// Frosted-glass surface (blueprint DESIGN SYSTEM).
/// Glass is for SURFACES (cards, sheets, nav) — primary actions stay solid.
/// BackdropFilter blur + translucent tint + 1pt hairline border + soft shadow.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radiusCard,
    this.borderRadius,
    this.opacity,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Overrides [radius] when a non-uniform corner shape is needed
  /// (e.g. sheets: rounded TOP corners only).
  final BorderRadius? borderRadius;

  /// Defaults to the card tint (0.60); sheets pass AppColors.glassSheetOpacity.
  final double? opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Solid cards on a clean background (no blur: crisper and much faster).
    final fill = brightness == Brightness.dark ? AppColors.plumCharcoal : Colors.white;
    final corners = borderRadius ?? BorderRadius.circular(radius);
    final card = Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: corners,
            border: Border.all(color: AppColors.glassBorder(brightness), width: 1),
          ),
          child: Material(type: MaterialType.transparency, child: child),
        );
    final content = ClipRRect(borderRadius: corners, child: card);
    final shadowed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: AppColors.glassShadow,
      ),
      child: content,
    );
    if (onTap == null) return shadowed;
    return GestureDetector(onTap: onTap, child: shadowed);
  }
}

/// Provides "go back one step" to onboarding pages, which are swapped by
/// RootFlow rather than pushed (so Navigator alone can't pop them).
class OnboardingBack extends InheritedWidget {
  const OnboardingBack({super.key, required this.onBack, required super.child});

  final VoidCallback onBack;

  static VoidCallback? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnboardingBack>()?.onBack;

  @override
  bool updateShouldNotify(OnboardingBack oldWidget) => onBack != oldWidget.onBack;
}

/// Scaffold with a full-bleed background under a soft theme scrim — the
/// "first-eye" look of the brand. With a photographic [backgroundAsset]
/// the photo gets a very subtle slow Ken Burns drift; without one, the
/// living [AuroraBackground] (drifting crimson/coral/plum blobs) renders
/// instead of a flat gradient. Both respect Reduce Motion.
/// Text over imagery keeps a scrim so contrast passes WCAG AA.
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
    // Every page gets a back button: onboarding steps via OnboardingBack,
    // pushed pages via the Navigator. Tab roots (nothing to go back to)
    // stay clean.
    final onboardingBack = OnboardingBack.maybeOf(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final bar = appBar ??
        (onboardingBack != null || canPop
            ? AppBar(
                leading: BackButton(
                  onPressed: onboardingBack ?? () => Navigator.of(context).maybePop(),
                ),
              )
            : null);
    return Scaffold(
      appBar: bar,
      extendBody: true,
      extendBodyBehindAppBar: true,
      // Clean white (or ink in dark mode): no background photos or motion.
      body: SafeArea(child: body),
      bottomNavigationBar: bottomBar,
    );
  }
}

/// Shows a modal glass sheet (radius 24 TOP corners only, 80% tint per
/// blueprint). Content scrolls when it outgrows the sheet — long sheets
/// (report trees, guides) must never clip or overflow.
Future<T?> showGlassSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.92,
        ),
        child: GlassContainer(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusCard),
          ),
          opacity: AppColors.glassSheetOpacity,
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 28),
          // Every sheet has a visible way out, not just swipe-down.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SingleChildScrollView(child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
