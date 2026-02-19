import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../utils/ui_text_utils.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/spiritual_background.dart';

class VersesScreen extends StatefulWidget {
  const VersesScreen({super.key});

  @override
  State<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(syncAll: true);
    });
  }

  Future<void> _refresh({
    bool syncAll = false,
    bool forceResync = false,
  }) async {
    final appState = context.read<AppState>();
    await appState.refreshVerseChapters();
    if (syncAll) {
      await appState.syncAllVerses(
        force: true,
        allowDowngradeOverwrite: forceResync,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final friendlyError = appState.versesError == null
        ? null
        : mapFriendlyError(
            appState.versesError!,
            strings: strings,
            context: 'verses',
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('verses_browser')),
        actions: <Widget>[
          IconButton(
            tooltip: strings.t('verses_sync'),
            onPressed: appState.versesLoading ? null : () => _refresh(syncAll: true),
            icon: const Icon(Icons.sync_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: strings.t('verses_sync_more_actions'),
            onSelected: (value) {
              if (value == 'force_resync') {
                _refresh(syncAll: true, forceResync: true);
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'force_resync',
                child: Text(strings.t('verses_force_resync')),
              ),
            ],
          ),
        ],
      ),
      body: SpiritualBackground(
        animate: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(syncAll: true),
          child: appState.chapters.isEmpty && friendlyError != null
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              friendlyError,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: () => _refresh(syncAll: true),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(strings.t('retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    if (appState.versesSyncPartialWarning) ...<Widget>[
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.65),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            appState.versesSyncWarningMessage ??
                                strings.t('verses_sync_incomplete_server_keep_offline'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${strings.t('verse_sync_count')}: ${appState.totalVersesAvailable}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (friendlyError != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: <Widget>[
                              Expanded(child: Text(friendlyError)),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _refresh(syncAll: true),
                                child: Text(strings.t('try_again')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...appState.chapters.map(
                      (chapter) {
                        final cached = appState.chapterVersesFor(chapter.chapter);
                        final displayCount =
                            cached.isNotEmpty ? cached.length : chapter.verseCount;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                '${strings.t('chapter')} ${chapter.chapter}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                '$displayCount ${strings.t('verses')}',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/chapter',
                                arguments: chapter.chapter,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AppBottomNav(currentIndex: 1),
      ),
    );
  }
}
