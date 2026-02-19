import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class ChapterDetailScreen extends StatefulWidget {
  final ChapterSummary chapter;

  const ChapterDetailScreen({super.key, required this.chapter});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadChapterVerses(widget.chapter.chapter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final chapter = widget.chapter;
    final verses = appState.versesForChapter(chapter.chapter);
    final loading = appState.isChapterLoading(chapter.chapter);
    final error = appState.chapterError(chapter.chapter);

    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.t('chapter')} ${chapter.chapter}'),
      ),
      body: SpiritualBackground(
        child: RefreshIndicator(
          onRefresh: () => appState.loadChapterVerses(
            chapter.chapter,
            forceRefresh: true,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        chapter.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chapter.summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${chapter.verseCount} ${strings.t('verses')}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (appState.offlineMode) ...<Widget>[
                const SizedBox(height: 10),
                _OfflineNotice(text: strings.t('offline_chapter_notice')),
              ],
              const SizedBox(height: 10),
              if (loading && verses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null && verses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(error),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => appState.loadChapterVerses(
                            chapter.chapter,
                            forceRefresh: true,
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(strings.t('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              else if (verses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(strings.t('verses_empty')),
                )
              else
                ...verses.map(
                  (verse) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        title: Text('BG ${verse.ref}'),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            verse.localizedTranslation(appState.languageCode),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_rounded),
                        onTap: () => Navigator.pushNamed(context, '/verse',
                            arguments: verse),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  final String text;

  const _OfflineNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
