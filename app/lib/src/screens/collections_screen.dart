import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final collections = appState.bookmarkCollections;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('collections'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, strings),
        child: const Icon(Icons.add),
      ),
      body: SpiritualBackground(
        child: collections.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[Text(strings.t('collections_empty'))],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.collections_bookmark_rounded),
                      title: Text(collection.name),
                      subtitle: Text(
                        '${collection.items.length} item${collection.items.length == 1 ? '' : 's'}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'rename') {
                            _showRenameDialog(
                                context, strings, collection);
                          } else if (value == 'delete') {
                            context
                                .read<AppState>()
                                .deleteCollection(collection.id);
                          }
                        },
                        itemBuilder: (_) => <PopupMenuEntry<String>>[
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(strings.t('rename_collection')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(strings.t('delete_collection')),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => _CollectionDetailScreen(
                            collectionId: collection.id,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AppStrings strings) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('create_collection')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: strings.t('collection_name'),
            hintText: strings.t('collection_name_hint'),
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              context.read<AppState>().createCollection(controller.text);
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<AppState>().createCollection(controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(strings.t('create')),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    AppStrings strings,
    BookmarkCollection collection,
  ) {
    final controller = TextEditingController(text: collection.name);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('rename_collection')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: strings.t('collection_name'),
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              context
                  .read<AppState>()
                  .renameCollection(collection.id, controller.text);
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context
                    .read<AppState>()
                    .renameCollection(collection.id, controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(strings.t('create')),
          ),
        ],
      ),
    );
  }
}

// ── Collection detail screen ────────────────────────────────────────

class _CollectionDetailScreen extends StatelessWidget {
  final String collectionId;

  const _CollectionDetailScreen({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);

    final collection = appState.bookmarkCollections
        .cast<BookmarkCollection?>()
        .firstWhere((c) => c!.id == collectionId, orElse: () => null);

    if (collection == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Collection not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: SpiritualBackground(
        child: collection.items.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  Text(strings.t('collection_items_empty')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: collection.items.length,
                itemBuilder: (context, index) {
                  final item = collection.items[index];
                  return _BookmarkItemCard(
                    item: item,
                    strings: strings,
                    onRemove: () => context
                        .read<AppState>()
                        .removeItemFromCollection(collectionId, item.id),
                    onTap: () {
                      if (item.type == 'verse' && item.verseId != null) {
                        Navigator.pushNamed(
                          context,
                          '/verse',
                          arguments: Verse(
                            id: item.verseId!,
                            chapter: 0,
                            verseNumber: 0,
                            ref: item.verseRef ?? '',
                            sanskrit: item.sanskrit ?? '',
                            transliteration: '',
                            translation: item.translation ?? '',
                            tags: const <String>[],
                          ),
                        );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _BookmarkItemCard extends StatelessWidget {
  final BookmarkItem item;
  final AppStrings strings;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _BookmarkItemCard({
    required this.item,
    required this.strings,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVerse = item.type == 'verse';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    isVerse
                        ? Icons.menu_book_rounded
                        : Icons.auto_awesome_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isVerse
                        ? '${strings.t('verse_bookmark')} ${item.verseRef ?? ''}'
                        : strings.t('answer_bookmark'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onRemove,
                    tooltip: strings.t('remove_from_collection'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (isVerse && item.sanskrit != null) ...<Widget>[
                Text(
                  item.sanskrit!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Text(
                isVerse
                    ? (item.translation ?? '')
                    : (item.answerText ?? ''),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isVerse && item.question != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Q: ${item.question}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared dialog to pick collection and add an item ──────────────

/// Shows a bottom sheet to pick a collection (or create a new one) then adds
/// [item] to that collection. Can be called from verse detail or chat.
Future<void> showAddToCollectionSheet({
  required BuildContext context,
  required BookmarkItem item,
}) async {
  final appState = context.read<AppState>();
  final strings = AppStrings(appState.languageCode);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _AddToCollectionSheet(
      item: item,
      strings: strings,
    ),
  );
}

class _AddToCollectionSheet extends StatelessWidget {
  final BookmarkItem item;
  final AppStrings strings;

  const _AddToCollectionSheet({
    required this.item,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final collections = appState.bookmarkCollections;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              strings.t('add_to_collection'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (collections.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  strings.t('collections_empty'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ...collections.map(
              (collection) => ListTile(
                leading: const Icon(Icons.collections_bookmark_rounded),
                title: Text(collection.name),
                subtitle: Text(
                  '${collection.items.length} item${collection.items.length == 1 ? '' : 's'}',
                ),
                onTap: () {
                  appState.addItemToCollection(collection.id, item);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${strings.t('added_to_collection')}: ${collection.name}',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateAndAddDialog(context, item, strings);
                },
                icon: const Icon(Icons.add),
                label: Text(strings.t('create_collection')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAndAddDialog(
    BuildContext context,
    BookmarkItem item,
    AppStrings strings,
  ) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('create_collection')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: strings.t('collection_name'),
            hintText: strings.t('collection_name_hint'),
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              _createAndAdd(context, controller.text, item);
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _createAndAdd(context, controller.text, item);
                Navigator.pop(dialogContext);
              }
            },
            child: Text(strings.t('create')),
          ),
        ],
      ),
    );
  }

  void _createAndAdd(
    BuildContext context,
    String collectionName,
    BookmarkItem item,
  ) {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);
    appState.createCollection(collectionName);
    // The newly created collection is the last one.
    final newCollection = appState.bookmarkCollections.last;
    appState.addItemToCollection(newCollection.id, item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${strings.t('added_to_collection')}: ${newCollection.name}',
        ),
      ),
    );
  }
}
