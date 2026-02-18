import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/share_card_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/spiritual_background.dart';

class VerseDetailScreen extends StatefulWidget {
  final Verse verse;

  const VerseDetailScreen({super.key, required this.verse});

  @override
  State<VerseDetailScreen> createState() => _VerseDetailScreenState();
}

class _VerseDetailScreenState extends State<VerseDetailScreen> {
  late Verse _verse;

  @override
  void initState() {
    super.initState();
    _verse = widget.verse;
  }

  Future<void> _openAdjacentVerse(int delta) async {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);
    final candidateId = _verse.id + delta;
    if (candidateId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('verse_chapter_boundary'))),
      );
      return;
    }

    try {
      final candidate = await appState.repository.getVerseById(candidateId);
      if (!mounted) {
        return;
      }
      if (candidate.chapter != _verse.chapter) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.t('verse_chapter_boundary'))),
        );
        return;
      }
      setState(() => _verse = candidate);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.t('verse_unavailable'))),
      );
    }
  }

  void _openAskScreen() {
    Navigator.pushNamed(context, '/ask');
  }

  Future<void> _openRandomVerse(AppStrings strings) async {
    final appState = context.read<AppState>();
    final random = await appState.randomVerse();
    if (!mounted || random == null) {
      return;
    }
    setState(() => _verse = random);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('random_verse'))),
    );
  }

  void _openChapters() {
    Navigator.pushNamed(context, '/verses');
  }

  void _showRecitePlaceholder(AppStrings strings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('chanting_audio_coming_soon'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final isFavorite = appState.isFavorite(_verse.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Verse ${_verse.ref}'),
      ),
      body: SpiritualBackground(
        animate: false,
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -220) {
              _openAdjacentVerse(1);
            } else if (velocity > 220) {
              _openAdjacentVerse(-1);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(strings.t('meaning'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_verse.translation),
              const SizedBox(height: 16),
              Card(
                child: ExpansionTile(
                  title: Text(strings.t('show_original_text')),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      strings.t('sanskrit'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _verse.sanskrit,
                      style: AppTheme.sanskritStyle(
                        context,
                        fontSize: 23,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.t('transliteration'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_verse.transliteration),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    strings.t('chanting_audio_coming_soon'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  TextButton.icon(
                    onPressed: () => _openAdjacentVerse(-1),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(strings.t('previous_verse')),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openAdjacentVerse(1),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(strings.t('next_verse')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => _openRandomVerse(strings),
                    icon: const Icon(Icons.casino_outlined),
                    label: Text(strings.t('random_verse')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openChapters,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(strings.t('browse_chapters')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _verse.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color:
                    Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _VerseQuickAction(
                  icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  label: strings.t('bookmark'),
                  onTap: () => context.read<AppState>().toggleFavorite(_verse),
                ),
              ),
              Expanded(
                child: _VerseQuickAction(
                  icon: Icons.share_outlined,
                  label: strings.t('share'),
                  onTap: () => ShareCardService.shareVerseCard(context, _verse),
                ),
              ),
              Expanded(
                child: _VerseQuickAction(
                  icon: Icons.auto_awesome_outlined,
                  label: strings.t('ask_gita'),
                  onTap: _openAskScreen,
                ),
              ),
              Expanded(
                child: _VerseQuickAction(
                  icon: Icons.graphic_eq_outlined,
                  label: strings.t('recite'),
                  onTap: () => _showRecitePlaceholder(strings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _VerseQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
