import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class HeroVerseCard extends StatelessWidget {
  final Verse verse;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onToggleSaved;
  final String shareLabel;
  final String saveLabel;

  const HeroVerseCard({
    super.key,
    required this.verse,
    required this.isSaved,
    required this.shareLabel,
    required this.saveLabel,
    this.onTap,
    this.onShare,
    this.onToggleSaved,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF6F3A17),
            Color(0xFFA46026),
            Color(0xFFC27A34),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF6F3A17).withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -22,
                bottom: -22,
                child: Icon(
                  Icons.spa_rounded,
                  size: 160,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Hero(
                        tag: _heroTag(verse),
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            'BG ${verse.ref}',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verse.sanskrit,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sanskritStyle(
                        context,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      verse.translation,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: onShare,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: Text(shareLabel),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: onToggleSaved,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 18,
                          ),
                          label: Text(saveLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _heroTag(Verse verse) {
  final token = verse.id > 0 ? verse.id.toString() : verse.ref;
  return 'verse-ref-$token';
}
