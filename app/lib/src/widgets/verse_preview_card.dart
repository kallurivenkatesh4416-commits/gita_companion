import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class VersePreviewCard extends StatelessWidget {
  final Verse verse;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final String? shareTooltip;
  final int translationMaxLines;
  final bool showTransliteration;
  final bool showTags;

  const VersePreviewCard({
    super.key,
    required this.verse,
    this.onTap,
    this.onShare,
    this.shareTooltip,
    this.translationMaxLines = 4,
    this.showTransliteration = true,
    this.showTags = true,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final colorScheme = Theme.of(context).colorScheme;
    final translation = verse.localizedTranslation(appState.languageCode);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            // Om watermark
            Positioned(
              right: 16,
              bottom: 12,
              child: Text(
                '\u0950', // Om symbol
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 120,
                  fontWeight: FontWeight.w300,
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  height: 1,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${strings.t('bhagavad_gita')} ${verse.ref}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (onShare != null)
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: onShare,
                          tooltip: shareTooltip ?? '',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (onShare != null) const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // English translation — primary hierarchy
                  Text(
                    translation,
                    maxLines: translationMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                  if (showTransliteration) ...<Widget>[
                    const SizedBox(height: 10),
                    // Transliteration — smaller, italic, secondary hierarchy
                    Text(
                      verse.transliteration,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                            height: 1.4,
                          ),
                    ),
                  ],
                  if (showTags) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: verse.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
