import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/api/api_client.dart';
import 'src/models/models.dart';
import 'src/repositories/gita_repository.dart';
import 'src/screens/ask_screen.dart';
import 'src/screens/favorites_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/journeys_screen.dart';
import 'src/screens/mood_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/ritual_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/verse_detail_screen.dart';
import 'src/state/app_state.dart';
import 'src/theme/app_theme.dart';

void main() {
  final repository = GitaRepository(ApiClient());
  runApp(GitaCompanionApp(repository: repository));
}

class GitaCompanionApp extends StatelessWidget {
  final GitaRepository repository;

  const GitaCompanionApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(repository: repository)..initialize(),
      child: MaterialApp(
        title: 'Gita Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routes: <String, WidgetBuilder>{
          '/': (_) => const _RootScreen(),
          '/ask': (_) => const AskScreen(),
          '/chat': (_) => const AskScreen(),
          '/mood': (_) => const MoodCheckInScreen(),
          '/ritual': (_) => const RitualScreen(),
          '/favorites': (_) => const FavoritesScreen(),
          '/journeys': (_) => const JourneysScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verse') {
            final verse = settings.arguments;
            if (verse is Verse) {
              return MaterialPageRoute<void>(
                builder: (_) => VerseDetailScreen(verse: verse),
              );
            }
          }

          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Route not found')),
            ),
          );
        },
      ),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.initialized || appState.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!appState.onboardingComplete) {
          return const OnboardingScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
