import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wave 1 · Real Capture tag (CROWD-FEATURES #2).
///
/// Shown ONLY when the member's media carries in-app capture provenance
/// ([Member.hasRealCaptureMedia] / per-surface source states). Uploaded
/// and placeholder media never render this widget — callers gate on the
/// provenance state, the badge itself never guesses.
///
/// The claim is precise: "captured in-app, unedited" — a provenance
/// statement about the capture pipeline (C2PA-style credential in
/// production), NOT a claim that a photo is "real" in any deeper sense.
class RealCaptureBadge extends StatelessWidget {
  const RealCaptureBadge({super.key, this.compact = false});

  /// Compact = icon + 'Real Capture' at caption size (Discover cards).
  /// Full adds the 'captured in-app · unedited' qualifier (profiles).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Design Wave: a QUIET text-row badge, not a glowing tag — on light
    // surfaces it is white with a hairline and ink text; on dark/photo
    // surfaces it keeps the deep pill so it stays legible. The camera
    // glyph carries the one accent colour.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'Real Capture · captured in-app, unedited',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.midnight.withValues(alpha: 0.55)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark
                ? AppColors.sparkCoral.withValues(alpha: 0.75)
                : AppColors.glassBorder(Brightness.light),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: compact ? 11 : 13,
              color: AppColors.emberCrimson,
            ),
            const SizedBox(width: 4),
            Text(
              compact
                  ? 'Real Capture'
                  : 'Real Capture · captured in-app, unedited',
              style: TextStyle(
                color: isDark ? AppColors.warmIvory : AppColors.midnight,
                fontSize: compact ? 10 : 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
