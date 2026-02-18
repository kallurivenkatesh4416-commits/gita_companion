import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class TagVersesScreen extends StatefulWidget {
  final String tag;

  const TagVersesScreen({super.key, required this.tag});

  @override
  State<TagVersesScreen> createState() => _TagVersesScreenState();
}

class _TagVersesScreenState extends State<TagVersesScreen> {
  bool _loading = true;
  List<Verse> _matches = const <Verse>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh({bool forceSync = false}) async {
    final appState = context.read<AppState>();
    if (forceSync || appState.chapterVerseCache.isEmpty) {
      await appState.syncAllVerses(force: true);
    }

    final normalizedTag = widget.tag.trim().toLowerCase();
    final allVerses = appState.chapterVerseCache.values
        .expand((items) => items)
        .toList(growable: false)
      ..sort((a, b) {
        if (a.chapter != b.chapter) {
          return a.chapter.compareTo(b.chapter);
        }
        return a.verseNumber.compareTo(b.verseNumber);
      });

    final filtered = allVerses.where((verse) {
      return verse.tags.any((tag) {
        final normalized = tag.trim().toLowerCase();
        return normalized == normalizedTag || normalized.contains(normalizedTag);
      });
    }).toList(growable: false);

    if (!mounted) {
      return;
    }
    setState(() {
      _matches = filtered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.t('tag_verses')}: #${widget.tag}'),
      ),
      body: SpiritualBackground(
        animate: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (_loading) ...<Widget>[
                const SizedBox(height: 48),
                const Center(child: CircularProgressIndicator()),
              ] else if (_matches.isEmpty) ...<Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(strings.t('tag_verses_empty')),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _refresh(forceSync: true),
                          icon: const Icon(Icons.sync_rounded),
                          label: Text(strings.t('verses_sync')),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${strings.t('tag_verses_count')}: ${_matches.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                ..._matches.map(
                  (verse) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          'BG ${verse.ref}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          verse.translation,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/verse',
                          arguments: verse,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
