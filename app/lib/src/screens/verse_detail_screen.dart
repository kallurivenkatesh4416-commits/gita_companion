import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import 'ask_screen.dart';
import 'collections_screen.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';
import '../widgets/verse_recitation_control.dart';

class VerseDetailScreen extends StatefulWidget {
  final Verse verse;

  const VerseDetailScreen({super.key, required this.verse});

  @override
  State<VerseDetailScreen> createState() => _VerseDetailScreenState();
}

class _VerseDetailScreenState extends State<VerseDetailScreen> {
  bool _recitationPlaying = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final verse = widget.verse;
    final isFavorite = appState.isFavorite(verse.id);
    final highlightColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('BG ${verse.ref}'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: strings.t('add_to_collection'),
            onPressed: () => showAddToCollectionSheet(
              context: context,
              item: BookmarkItem.fromVerse(verse),
            ),
          ),
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => context.read<AppState>().toggleFavorite(verse),
          ),
        ],
      ),
      body: SpiritualBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(strings.t('sanskrit'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(verse.sanskrit, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            if (verse.transliteration.trim().isNotEmpty) ...<Widget>[
              Text(strings.t('transliteration'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _recitationPlaying
                      ? highlightColor.withValues(alpha: 0.10)
                      : Colors.transparent,
                ),
                child: Text(verse.transliteration),
              ),
              const SizedBox(height: 16),
            ],
            Text(strings.t('meaning'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(verse.translation),
            const SizedBox(height: 16),
            VerseRecitationControl(
              verse: verse,
              strings: strings,
              onPlaybackChanged: (playing) {
                if (!mounted) {
                  return;
                }
                setState(() => _recitationPlaying = playing);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: AskScreenArguments(verseContext: verse),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text(strings.t('ask_about_this_verse')),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: verse.tags
                  .map((tag) => Chip(label: Text(tag)))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
