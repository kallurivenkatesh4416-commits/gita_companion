import 'package:flutter/material.dart';

import '../models/models.dart';

class GuidancePanel extends StatelessWidget {
  final GuidanceResponse guidance;

  const GuidancePanel({super.key, required this.guidance});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                guidance.mode == 'comfort' ? 'Comfort Guidance' : 'Clarity Guidance',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.secondary,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Text(guidance.guidanceShort, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(guidance.guidanceLong),
            const SizedBox(height: 14),
            Divider(color: colorScheme.outline.withValues(alpha: 0.45), height: 1),
            const SizedBox(height: 12),
            Text(
              'Micro-practice: ${guidance.microPractice.title}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...guidance.microPractice.steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('- $step'),
              ),
            ),
            const SizedBox(height: 8),
            Text('Duration: ${guidance.microPractice.durationMinutes} minute(s)'),
            const SizedBox(height: 12),
            Text(
              'Reflection prompt',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(guidance.reflectionPrompt),
          ],
        ),
      ),
    );
  }
}
