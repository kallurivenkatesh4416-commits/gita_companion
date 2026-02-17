import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: RefreshIndicator(
        onRefresh: () => appState.refreshFavorites(),
        child: appState.favorites.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const <Widget>[
                  Text('No favorites yet. Save a verse from the verse detail screen.'),
                ],
              )
            : ListView.builder(
                itemCount: appState.favorites.length,
                itemBuilder: (context, index) {
                  final favorite = appState.favorites[index];
                  return Card(
                    child: ListTile(
                      title: Text('Verse ${favorite.verse.ref}'),
                      subtitle: Text(
                        favorite.verse.translation,
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
                        onPressed: () => context.read<AppState>().toggleFavorite(favorite.verse),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
