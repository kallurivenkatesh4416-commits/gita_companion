import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/api/api_client.dart';
import 'src/calendar/calendar_state.dart';
import 'src/i18n/app_strings.dart';
import 'src/models/models.dart';
import 'src/repositories/gita_repository.dart';
import 'src/screens/ask_screen.dart';
import 'src/screens/chapter_detail_screen.dart';
import 'src/screens/chapter_list_screen.dart';
import 'src/screens/collections_screen.dart';
import 'src/screens/favorites_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/journal_screen.dart';
import 'src/screens/journeys_screen.dart';
import 'src/screens/mood_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/panchang_screen.dart';
import 'src/screens/ritual_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/verses_screen.dart';
import 'src/screens/chapter_verses_screen.dart';
import 'src/screens/tag_verses_screen.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(repository: repository)..initialize(),
        ),
        ChangeNotifierProvider<CalendarState>(
          create: (_) => CalendarState()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Gita Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routes: <String, WidgetBuilder>{
          '/': (_) => const _RootScreen(),
          '/ask': (_) => const AskScreen(),
          '/chat': (_) => const AskScreen(),
          '/mood': (_) => const MoodCheckInScreen(),
          '/ritual': (_) => const RitualScreen(),
          '/chapters': (_) => const ChapterListScreen(),
          '/journal': (_) => const JournalScreen(),
          '/favorites': (_) => const FavoritesScreen(),
          '/collections': (_) => const CollectionsScreen(),
          '/journeys': (_) => const JourneysScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/verses':   (_) => const VersesScreen(),
          '/panchang': (_) => const PanchangScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/chapter') {
            final chapter = settings.arguments;
            if (chapter is ChapterSummary) {
              return MaterialPageRoute<void>(
                builder: (_) => ChapterDetailScreen(chapter: chapter),
              );
            }
          }

          if (settings.name == '/verse') {
            final verse = settings.arguments;
            if (verse is Verse) {
              return MaterialPageRoute<void>(
                builder: (_) => VerseDetailScreen(verse: verse),
              );
            }
          }
          if (settings.name == '/chapter') {
            final chapter = settings.arguments;
            if (chapter is int) {
              return MaterialPageRoute<void>(
                builder: (_) => ChapterVersesScreen(chapter: chapter),
              );
            }
          }
          if (settings.name == '/tag') {
            final tag = settings.arguments;
            if (tag is String && tag.trim().isNotEmpty) {
              return MaterialPageRoute<void>(
                builder: (_) => TagVersesScreen(tag: tag),
              );
            }
          }

          return MaterialPageRoute<void>(
            builder: (context) {
              final languageCode = context.read<AppState>().languageCode;
              final strings = AppStrings(languageCode);
              return Scaffold(
                body: Center(child: Text(strings.t('route_not_found'))),
              );
            },
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
