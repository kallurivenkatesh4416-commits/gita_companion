import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../utils/ui_text_utils.dart';
import '../widgets/spiritual_background.dart';

class ChapterVersesScreen extends StatefulWidget {
  final int chapter;

  const ChapterVersesScreen({super.key, required this.chapter});

  @override
  State<ChapterVersesScreen> createState() => _ChapterVersesScreenState();
}

class _ChapterVersesScreenState extends State<ChapterVersesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load(force: false);
    });
  }

  Future<void> _load({required bool force}) async {
    await context.read<AppState>().refreshChapterVerses(widget.chapter, force: force);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final verses = appState.chapterVersesFor(widget.chapter);
    final friendlyError = appState.versesError == null
        ? null
        : mapFriendlyError(
            appState.versesError!,
            strings: strings,
            context: 'verses',
          );

    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.t('chapter')} ${widget.chapter}'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _load(force: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: strings.t('retry'),
          ),
        ],
      ),
      body: SpiritualBackground(
        animate: false,
        child: RefreshIndicator(
          onRefresh: () => _load(force: true),
          child: verses.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              friendlyError ?? strings.t('chapter_has_no_verses'),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: () => _load(force: true),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(strings.t('retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: verses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final verse = verses[index];
                    return Card(
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
                    );
                  },
                ),
        ),
      ),
    );
  }
}
