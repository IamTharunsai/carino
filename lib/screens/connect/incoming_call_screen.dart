import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../../widgets/safety_actions.dart';
import '../../widgets/spark_button.dart';
import 'spark_session_screen.dart';

/// S-033 Incoming Spark Call — what a ringing invitation looks like.
///
/// Rules: it comes ONLY from someone you've matched with who you accepted
/// a Spark from (never strangers, never random); on the OS lock screen the
/// notification shows a GENERIC label ("Cariño · incoming video") — never
/// a name or photo (S-009 generic previews). Declining leaves a missed-
/// call state in the chat; nothing about a decline is ever announced.
class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                '${AppConfig.appName} · Spark video invite',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.softRose),
              ),
              const SizedBox(height: 6),
              Text(
                'On your lock screen this shows only as “incoming video” — '
                'never a name or photo.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.softRose),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CircleAvatar(
                radius: 52,
                backgroundImage: AssetImage(member.photoAsset),
              ),
              const SizedBox(height: 16),
              Text('${member.name}, ${member.age}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.warmIvory,
                      )),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(member.intention.label,
                      style: const TextStyle(color: AppColors.softRose)),
                  const SizedBox(width: 6),
                  if (member.verified)
                    const Icon(Icons.verified,
                        size: 15, color: AppColors.sparkCoral),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      GlassIconButton(
                        icon: Icons.call_end,
                        semanticLabel: 'Decline',
                        filled: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const SizedBox(height: 6),
                      const Text('Decline',
                          style: TextStyle(color: AppColors.warmIvory)),
                    ],
                  ),
                  Column(
                    children: [
                      GlassIconButton(
                        icon: Icons.videocam,
                        semanticLabel: 'Accept video',
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => SparkCallScreen(member: member),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Accept',
                          style: TextStyle(color: AppColors.warmIvory)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => SafetyActions.showForMember(
                  context,
                  member: member,
                  surface: 'Incoming call',
                ),
                child: const Text('Report or block'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
