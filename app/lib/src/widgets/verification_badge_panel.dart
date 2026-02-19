import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';

class VerificationBadgePanel extends StatelessWidget {
  final AppStrings strings;
  final String verificationLevel;
  final List<VerificationCheck> verificationDetails;
  final List<ProvenanceVerse> provenance;

  const VerificationBadgePanel({
    super.key,
    required this.strings,
    required this.verificationLevel,
    required this.verificationDetails,
    required this.provenance,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = verificationLevel.trim().toUpperCase();
    final levelColor = switch (level) {
      'VERIFIED' => const Color(0xFF2E7D32),
      'REVIEWED' => const Color(0xFF8D6E00),
      _ => const Color(0xFF8E4A2F),
    };

    final levelText = switch (level) {
      'VERIFIED' => strings.t('verification_verified'),
      'REVIEWED' => strings.t('verification_reviewed'),
      _ => strings.t('verification_raw'),
    };

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  levelText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: levelColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.t('verification_details'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          children: <Widget>[
            if (provenance.isNotEmpty) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.t('verification_verses_used'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 6),
              ...provenance.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'BG ${item.chapter}.${item.verse} - ${item.translationSource}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        item.sanskrit,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (verificationDetails.isNotEmpty) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.t('verification_checks'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 6),
              ...verificationDetails.map(
                (check) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        check.passed
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 16,
                        color: check.passed
                            ? const Color(0xFF2E7D32)
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '[${check.passed ? strings.t('verification_pass') : strings.t('verification_fail')}] ${check.name}: ${check.note}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
