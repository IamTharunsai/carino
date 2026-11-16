import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/spark_button.dart';

/// S-051 Report Confirmation — a real screen, never just a snackbar:
/// the server-issued case reference, what happens next, the response SLA,
/// and the appeals path. The reference shown here is the one
/// BackendService.submitReport returned (live) or the clearly-prefixed
/// demo ref in mock mode — the UI never invents one.
class ReportConfirmationScreen extends StatelessWidget {
  const ReportConfirmationScreen({
    super.key,
    required this.caseRef,
    required this.category,
  });

  final String caseRef;
  final String category;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassScaffold(
      appBar: AppBar(title: const Text('Report received')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.check_circle_outline, size: 52, color: Color(0xFFFF6B6B)),
          const SizedBox(height: 14),
          Text('Thanks — a person will review this.',
              style: text.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Case reference', style: text.bodySmall),
                Text(caseRef,
                    style: text.titleLarge?.copyWith(letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Text('Category: $category', style: text.bodyMedium),
                const SizedBox(height: 10),
                Text(
                  'What happens next:\n'
                  '• A human Trust reviewer looks at your report and the '
                  'sealed evidence attached to it.\n'
                  '• First review within 24 hours — urgent safety reports '
                  'jump the queue.\n'
                  '• The person never learns who reported them.\n'
                  '• You\'ll get the outcome in Notifications.',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SparkButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 8),
          Text(
            'If you are in immediate danger, contact local emergency '
            'services first — then report here.',
            style: text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
