import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    context.read<AppState>().refreshFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('favorites'))),
      body: SpiritualBackground(
        child: RefreshIndicator(
          onRefresh: () => appState.refreshFavorites(),
          child: appState.favoritesLoading && appState.favorites.isEmpty
              ? const _FavoritesSkeletonList()
              : appState.favorites.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: <Widget>[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  Icons.favorite_border_rounded,
                                  size: 46,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  strings.t('favorites_empty'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  strings.t('empty_state_hint_favorites'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: appState.favorites.length,
                      itemBuilder: (context, index) {
                        final favorite = appState.favorites[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${strings.t('verse_bookmark')} ${favorite.verse.ref}',
                            ),
                            subtitle: Text(
                              favorite.verse
                                  .localizedTranslation(appState.languageCode),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/verse',
                              arguments: favorite.verse,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => context
                                  .read<AppState>()
                                  .toggleFavorite(favorite.verse),
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

class _FavoritesSkeletonList extends StatelessWidget {
  const _FavoritesSkeletonList();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withValues(alpha: 0.16);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      itemCount: 4,
      itemBuilder: (_, __) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 220,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
