import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'spark_button.dart';

/// S-059 — Empty / Error / Permission State Kit.
///
/// Reusable states for every screen. The rules (blueprint S-059):
///  - Empty: the TRUE reason + the next real action. Never filler people,
///    never a fake "someone is waiting" tease.
///  - Loading: surface-colour skeletons — NEVER a fake photo or fake person.
///  - Error: plain language + Retry + a route to Support (S-053). No raw
///    error codes are ever shown to members.
///  - Offline: say what is queued, honestly (e.g. "Report queued — it will
///    send when you reconnect").
///  - Permission-denied: what is blocked, the steps to fix it, and a
///    Settings route — a feature-level re-ask, never a nag loop.

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: AppColors.sparkCoral),
              const SizedBox(height: 12),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(body,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                SparkButton(
                    label: actionLabel!, secondary: true, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton — surface-colour blocks in the shape of the content.
class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({super.key, this.cards = 2});

  final int cards;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface.withValues(alpha: 0.5);
    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < cards; i++) ...[
          block(220),
          const SizedBox(height: 10),
          block(16),
          const SizedBox(height: 6),
          block(16),
          const SizedBox(height: 18),
        ],
        const Center(
          child: Text('Loading…',
              style: TextStyle(color: AppColors.softRose, fontSize: 12)),
        ),
      ],
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.onRetry,
    this.onSupport,
    this.message = 'Something went wrong on our side, not yours.',
  });

  final VoidCallback onRetry;
  final VoidCallback? onSupport;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'That didn\'t load',
      body: message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

/// Offline notice — queued actions are stated, not hidden.
class AppOfflineState extends StatelessWidget {
  const AppOfflineState({super.key, this.queuedNote});

  /// e.g. "Your report is queued and will send on reconnect."
  final String? queuedNote;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.wifi_off_outlined,
      title: 'You\'re offline',
      body: queuedNote ??
          'Check your connection — anything you send will queue and go out when you\'re back.',
    );
  }
}

/// Permission-denied state: what is blocked + steps + Settings route.
class PermissionDeniedState extends StatelessWidget {
  const PermissionDeniedState({
    super.key,
    required this.permissionLabel, // e.g. 'Camera'
    required this.whyNeeded,
    this.onOpenSettings,
  });

  final String permissionLabel;
  final String whyNeeded;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: AppColors.sparkCoral),
              const SizedBox(width: 8),
              Text('$permissionLabel is off',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(whyNeeded, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            'To fix it: open Settings → Apps → ${AppConfig.appName} → Permissions → '
            '$permissionLabel → Allow. We\'ll only ever ask again at the '
            'moment you use the feature — never in a nag loop.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SparkButton(
            label: 'Open Settings',
            icon: Icons.settings_outlined,
            secondary: true,
            // INTEGRATION POINT: app_settings / permission_handler
            // openAppSettings() in production.
            onPressed: onOpenSettings ?? () {},
          ),
        ],
      ),
    );
  }
}
