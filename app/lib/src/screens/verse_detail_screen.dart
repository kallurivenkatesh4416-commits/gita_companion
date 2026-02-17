import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class VerseDetailScreen extends StatelessWidget {
  final Verse verse;

  const VerseDetailScreen({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final isFavorite = appState.isFavorite(verse.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Verse ${verse.ref}'),
        actions: <Widget>[
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
            Text(strings.t('transliteration'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(verse.transliteration),
            const SizedBox(height: 16),
            Text(strings.t('meaning'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(verse.translation),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(strings.t('audio_placeholder_title')),
                subtitle: Text(strings.t('audio_placeholder_subtitle')),
                onTap: () {},
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
